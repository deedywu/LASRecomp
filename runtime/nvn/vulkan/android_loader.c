// Android Vulkan loader compatibility. Some emulator/native-bridge libvulkan shims advertise Vulkan 1.3 and
// return its commands from vkGetDeviceProcAddr, but do not export the corresponding ELF symbols. Keep the normal
// direct calls in the renderer while supplying the omitted entry points from the device dispatch table.
#ifdef __ANDROID__

#include <stdlib.h>

#include "vk.h"

static PFN_vkVoidFunction load_device(const char *core, const char *alias) {
    PFN_vkVoidFunction fn = vkGetDeviceProcAddr(g_vk.dev, core);
    if (!fn && alias) fn = vkGetDeviceProcAddr(g_vk.dev, alias);
    if (!fn) FATAL("Vulkan device command unavailable: %s / %s\n", core, alias ? alias : "-");
    return fn;
}

#define LOAD(type, core, alias) \
    static type fn; \
    if (!fn) fn = (type)load_device(core, alias)

VKAPI_ATTR void VKAPI_CALL vkCmdPipelineBarrier2(VkCommandBuffer cb, const VkDependencyInfo *info) {
    LOAD(PFN_vkCmdPipelineBarrier2, "vkCmdPipelineBarrier2", "vkCmdPipelineBarrier2KHR");
    fn(cb, info);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetCullMode(VkCommandBuffer cb, VkCullModeFlags mode) {
    LOAD(PFN_vkCmdSetCullMode, "vkCmdSetCullMode", "vkCmdSetCullModeEXT");
    fn(cb, mode);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetDepthBiasEnable(VkCommandBuffer cb, VkBool32 enabled) {
    LOAD(PFN_vkCmdSetDepthBiasEnable, "vkCmdSetDepthBiasEnable", "vkCmdSetDepthBiasEnableEXT");
    fn(cb, enabled);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetDepthCompareOp(VkCommandBuffer cb, VkCompareOp op) {
    LOAD(PFN_vkCmdSetDepthCompareOp, "vkCmdSetDepthCompareOp", "vkCmdSetDepthCompareOpEXT");
    fn(cb, op);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetDepthTestEnable(VkCommandBuffer cb, VkBool32 enabled) {
    LOAD(PFN_vkCmdSetDepthTestEnable, "vkCmdSetDepthTestEnable", "vkCmdSetDepthTestEnableEXT");
    fn(cb, enabled);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetDepthWriteEnable(VkCommandBuffer cb, VkBool32 enabled) {
    LOAD(PFN_vkCmdSetDepthWriteEnable, "vkCmdSetDepthWriteEnable", "vkCmdSetDepthWriteEnableEXT");
    fn(cb, enabled);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetFrontFace(VkCommandBuffer cb, VkFrontFace face) {
    LOAD(PFN_vkCmdSetFrontFace, "vkCmdSetFrontFace", "vkCmdSetFrontFaceEXT");
    fn(cb, face);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetPrimitiveRestartEnable(VkCommandBuffer cb, VkBool32 enabled) {
    LOAD(PFN_vkCmdSetPrimitiveRestartEnable, "vkCmdSetPrimitiveRestartEnable", "vkCmdSetPrimitiveRestartEnableEXT");
    fn(cb, enabled);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetPrimitiveTopology(VkCommandBuffer cb, VkPrimitiveTopology topology) {
    LOAD(PFN_vkCmdSetPrimitiveTopology, "vkCmdSetPrimitiveTopology", "vkCmdSetPrimitiveTopologyEXT");
    fn(cb, topology);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetStencilOp(VkCommandBuffer cb, VkStencilFaceFlags faces, VkStencilOp fail,
                                              VkStencilOp pass, VkStencilOp depth_fail, VkCompareOp compare) {
    LOAD(PFN_vkCmdSetStencilOp, "vkCmdSetStencilOp", "vkCmdSetStencilOpEXT");
    fn(cb, faces, fail, pass, depth_fail, compare);
}

VKAPI_ATTR void VKAPI_CALL vkCmdSetStencilTestEnable(VkCommandBuffer cb, VkBool32 enabled) {
    LOAD(PFN_vkCmdSetStencilTestEnable, "vkCmdSetStencilTestEnable", "vkCmdSetStencilTestEnableEXT");
    fn(cb, enabled);
}

VKAPI_ATTR void VKAPI_CALL vkCmdWriteTimestamp2(VkCommandBuffer cb, VkPipelineStageFlags2 stage, VkQueryPool pool,
                                                 uint32_t query) {
    LOAD(PFN_vkCmdWriteTimestamp2, "vkCmdWriteTimestamp2", "vkCmdWriteTimestamp2KHR");
    fn(cb, stage, pool, query);
}

VKAPI_ATTR void VKAPI_CALL vkGetDeviceImageMemoryRequirements(VkDevice device,
                                                               const VkDeviceImageMemoryRequirements *info,
                                                               VkMemoryRequirements2 *requirements) {
    static PFN_vkGetDeviceImageMemoryRequirements fn;
    if (!fn) {
        fn = (PFN_vkGetDeviceImageMemoryRequirements)vkGetDeviceProcAddr(device, "vkGetDeviceImageMemoryRequirements");
        if (!fn)
            fn = (PFN_vkGetDeviceImageMemoryRequirements)vkGetDeviceProcAddr(device,
                                                                             "vkGetDeviceImageMemoryRequirementsKHR");
        if (!fn) FATAL("Vulkan device command unavailable: vkGetDeviceImageMemoryRequirements\n");
    }
    fn(device, info, requirements);
}

VKAPI_ATTR VkResult VKAPI_CALL vkQueueSubmit2(VkQueue queue, uint32_t count, const VkSubmitInfo2 *submits,
                                               VkFence fence) {
    LOAD(PFN_vkQueueSubmit2, "vkQueueSubmit2", "vkQueueSubmit2KHR");
    return fn(queue, count, submits, fence);
}

#endif
