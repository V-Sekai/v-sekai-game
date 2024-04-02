extends Node


# Converts an euler float within the range of -PI to PI into a 16-bit
# quantized representation.
static func quantize_euler_angle_to_s16_angle(p_angle: float) -> int:
	return int((p_angle / PI) * 32767.0)


# Converts a 16-bit quantized angle into an euler float between -PI and PI.
static func dequantize_s16_angle_to_euler_angle(p_s16_angle: int) -> float:
	return (float(p_s16_angle) / 32767.0) * PI
