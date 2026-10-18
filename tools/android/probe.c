#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include <vulkan/vulkan.h>

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

#define GUEST_LO 0x7000000000ull
#define GUEST_HI 0x7320000000ull

static int has_extension(const VkExtensionProperties *extensions, uint32_t count, const char *name) {
    for (uint32_t i = 0; i < count; i++)
        if (!strcmp(extensions[i].extensionName, name)) return 1;
    return 0;
}

static void print_version(const char *label, uint32_t version) {
    printf("%s %u.%u.%u\n", label, VK_API_VERSION_MAJOR(version), VK_API_VERSION_MINOR(version),
           VK_API_VERSION_PATCH(version));
}

int main(void) {
    printf("page_size %ld\n", sysconf(_SC_PAGESIZE));
    size_t guest_size = (size_t)(GUEST_HI - GUEST_LO);
    void *guest = mmap((void *)(uintptr_t)GUEST_LO, guest_size, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
    printf("guest_map %s requested=%#" PRIx64 " actual=%p size=%zu errno=%d\n",
           guest == (void *)(uintptr_t)GUEST_LO ? "ok" : "failed", (uint64_t)GUEST_LO, guest, guest_size,
           guest == MAP_FAILED ? errno : 0);
    if (guest != MAP_FAILED) munmap(guest, guest_size);

    uint32_t instance_version = VK_API_VERSION_1_0;
    PFN_vkEnumerateInstanceVersion enumerate_instance_version =
        (PFN_vkEnumerateInstanceVersion)vkGetInstanceProcAddr(VK_NULL_HANDLE, "vkEnumerateInstanceVersion");
    if (enumerate_instance_version) enumerate_instance_version(&instance_version);
    print_version("instance_api", instance_version);

    VkApplicationInfo app = {.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
                             .pApplicationName = "LASRecomp Android probe",
                             .apiVersion = instance_version};
    VkInstanceCreateInfo create = {.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, .pApplicationInfo = &app};
    VkInstance instance = VK_NULL_HANDLE;
    VkResult result = vkCreateInstance(&create, NULL, &instance);
    if (result != VK_SUCCESS) {
        printf("vkCreateInstance failed %d\n", result);
        return 2;
    }

    uint32_t device_count = 0;
    vkEnumeratePhysicalDevices(instance, &device_count, NULL);
    printf("physical_devices %u\n", device_count);
    VkPhysicalDevice devices[8];
    if (device_count > 8) device_count = 8;
    vkEnumeratePhysicalDevices(instance, &device_count, devices);
    for (uint32_t i = 0; i < device_count; i++) {
        VkPhysicalDeviceProperties properties;
        VkPhysicalDeviceFeatures features;
        vkGetPhysicalDeviceProperties(devices[i], &properties);
        vkGetPhysicalDeviceFeatures(devices[i], &features);
        printf("device %u %s\n", i, properties.deviceName);
        print_version("device_api", properties.apiVersion);
        printf("features shaderInt64=%u robustBufferAccess=%u textureCompressionBC=%u textureCompressionASTC_LDR=%u "
               "fragmentStoresAndAtomics=%u vertexPipelineStoresAndAtomics=%u\n",
               features.shaderInt64, features.robustBufferAccess, features.textureCompressionBC,
               features.textureCompressionASTC_LDR, features.fragmentStoresAndAtomics,
               features.vertexPipelineStoresAndAtomics);

        uint32_t extension_count = 0;
        vkEnumerateDeviceExtensionProperties(devices[i], NULL, &extension_count, NULL);
        VkExtensionProperties extensions[512];
        if (extension_count > 512) extension_count = 512;
        vkEnumerateDeviceExtensionProperties(devices[i], NULL, &extension_count, extensions);
        VkPhysicalDeviceVertexAttributeDivisorFeaturesEXT divisor = {
            .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT};
        VkPhysicalDeviceCustomBorderColorFeaturesEXT border = {
            .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_CUSTOM_BORDER_COLOR_FEATURES_EXT};
        VkPhysicalDeviceFaultFeaturesEXT fault = {.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FAULT_FEATURES_EXT};
        VkPhysicalDeviceVulkan13Features features13 = {.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
        VkPhysicalDeviceVulkan12Features features12 = {.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
                                                       .pNext = &features13};
        VkPhysicalDeviceVulkan11Features features11 = {.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES,
                                                       .pNext = &features12};
        VkPhysicalDeviceFeatures2 features2 = {.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
                                               .pNext = &features11};
        void **feature_tail = &features13.pNext;
        if (has_extension(extensions, extension_count, VK_EXT_VERTEX_ATTRIBUTE_DIVISOR_EXTENSION_NAME)) {
            *feature_tail = &divisor;
            feature_tail = &divisor.pNext;
        }
        if (has_extension(extensions, extension_count, VK_EXT_CUSTOM_BORDER_COLOR_EXTENSION_NAME)) {
            *feature_tail = &border;
            feature_tail = &border.pNext;
        }
        if (has_extension(extensions, extension_count, VK_EXT_DEVICE_FAULT_EXTENSION_NAME)) *feature_tail = &fault;
        vkGetPhysicalDeviceFeatures2(devices[i], &features2);
        printf("vulkan11 storageBuffer16BitAccess=%u\n", features11.storageBuffer16BitAccess);
        printf("vulkan12 timelineSemaphore=%u shaderInt8=%u samplerMirrorClampToEdge=%u "
               "uniformAndStorageBuffer8BitAccess=%u storageBuffer8BitAccess=%u scalarBlockLayout=%u\n",
               features12.timelineSemaphore, features12.shaderInt8, features12.samplerMirrorClampToEdge,
               features12.uniformAndStorageBuffer8BitAccess, features12.storageBuffer8BitAccess,
               features12.scalarBlockLayout);
        printf("vulkan13 dynamicRendering=%u synchronization2=%u shaderDemoteToHelperInvocation=%u "
               "shaderTerminateInvocation=%u maintenance4=%u\n",
               features13.dynamicRendering, features13.synchronization2, features13.shaderDemoteToHelperInvocation,
               features13.shaderTerminateInvocation, features13.maintenance4);
        printf("extension_features divisor=%u zeroDivisor=%u customBorderColors=%u customBorderWithoutFormat=%u "
               "deviceFault=%u\n",
               divisor.vertexAttributeInstanceRateDivisor, divisor.vertexAttributeInstanceRateZeroDivisor,
               border.customBorderColors, border.customBorderColorWithoutFormat, fault.deviceFault);
        static const char *const wanted[] = {
            VK_KHR_SWAPCHAIN_EXTENSION_NAME,
            "VK_KHR_dynamic_rendering",
            "VK_KHR_synchronization2",
            "VK_KHR_timeline_semaphore",
            "VK_KHR_maintenance4",
            "VK_KHR_8bit_storage",
            "VK_KHR_16bit_storage",
            "VK_EXT_scalar_block_layout",
            VK_EXT_EXTERNAL_MEMORY_HOST_EXTENSION_NAME,
            VK_EXT_VERTEX_ATTRIBUTE_DIVISOR_EXTENSION_NAME,
            VK_EXT_CUSTOM_BORDER_COLOR_EXTENSION_NAME,
        };
        for (size_t wanted_index = 0; wanted_index < sizeof wanted / sizeof wanted[0]; wanted_index++)
            printf("extension %s=%d\n", wanted[wanted_index],
                   has_extension(extensions, extension_count, wanted[wanted_index]));
    }
    vkDestroyInstance(instance, NULL);

    void *self = dlopen(NULL, RTLD_NOW);
    printf("dlopen_self %s\n", self ? "ok" : dlerror());
    if (self) dlclose(self);
    return 0;
}
