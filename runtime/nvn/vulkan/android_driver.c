// Android Vulkan driver selection.  The launcher imports a Turnip package into
// private app storage and passes its library in LARECOMP_VK_DRIVER.  adrenotools
// loads it in an isolated linker namespace; an unusable package falls back to
// Android's system driver.  volk supplies every Vulkan entry point afterwards.
#ifdef LARECOMP_CUSTOM_VULKAN

#include <adrenotools/driver.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "vk.h"

static bool driver_has_gpu(PFN_vkGetInstanceProcAddr gipa) {
    PFN_vkCreateInstance create = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
    if (!create) return false;
    VkApplicationInfo app = {.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO, .apiVersion = VK_API_VERSION_1_3};
    VkInstanceCreateInfo ci = {.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, .pApplicationInfo = &app};
    VkInstance inst;
    if (create(&ci, NULL, &inst) != VK_SUCCESS) return false;
    PFN_vkEnumeratePhysicalDevices enumerate =
        (PFN_vkEnumeratePhysicalDevices)gipa(inst, "vkEnumeratePhysicalDevices");
    PFN_vkGetPhysicalDeviceProperties props =
        (PFN_vkGetPhysicalDeviceProperties)gipa(inst, "vkGetPhysicalDeviceProperties");
    PFN_vkDestroyInstance destroy = (PFN_vkDestroyInstance)gipa(inst, "vkDestroyInstance");
    bool ok = false;
    uint32_t count = 0;
    if (enumerate && props && enumerate(inst, &count, NULL) == VK_SUCCESS && count) {
        VkPhysicalDevice devices[8];
        if (count > 8) count = 8;
        if (enumerate(inst, &count, devices) >= 0) {
            for (uint32_t i = 0; i < count && !ok; i++) {
                VkPhysicalDeviceProperties p;
                props(devices[i], &p);
                ok = p.apiVersion >= VK_API_VERSION_1_3;
            }
        }
    }
    if (destroy) destroy(inst, NULL);
    return ok;
}

void vk_android_load(void) {
    void *lib = NULL;
    const char *driver = getenv("LARECOMP_VK_DRIVER");
    const char *hooks = getenv("LARECOMP_NATIVE_LIB_DIR");
    if (driver && *driver && hooks && *hooks) {
        const char *slash = strrchr(driver, '/');
        char directory[1024];
        if (slash && (size_t)snprintf(directory, sizeof directory, "%.*s/",
                                     (int)(slash - driver), driver) < sizeof directory) {
            lib = adrenotools_open_libvulkan(RTLD_NOW | RTLD_LOCAL,
                                             ADRENOTOOLS_DRIVER_CUSTOM,
                                             NULL, hooks, directory, slash + 1,
                                             NULL, NULL);
        }
        LOG("[vk] custom driver %s: %s\n", driver,
            lib ? "loaded through adrenotools" : "load failed; using system driver");
        PFN_vkGetInstanceProcAddr gipa =
            lib ? (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr") : NULL;
        if (lib && (!gipa || !driver_has_gpu(gipa))) {
            LOG("[vk] custom driver has no compatible Vulkan 1.3 GPU; using system driver\n");
            lib = NULL;  // Driver libraries are intentionally left loaded.
        }
    }
    if (!lib) lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
    if (!lib) FATAL("no Vulkan driver: %s\n", dlerror());
    PFN_vkGetInstanceProcAddr gipa =
        (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
    if (!gipa) FATAL("the Vulkan driver has no vkGetInstanceProcAddr\n");
    volkInitializeCustom(gipa);
}

#endif
