#!/usr/bin/env bash

# Captures screenshots over an angle span

# Monado client executable
CLIENT_MONADO=$1
# Screenshot size
VIEW_WIDTH=$2
VIEW_HEIGHT=$3
# Time to wait between each frame screenshot
WAIT_TIME=$4
# Output directory
OUTDIR=$5
mkdir -p "$OUTDIR"

# Head position (constant)
PX=0.0
PY=1.5
PZ=0.2

# Loop over 0, 120, 240 degrees
ANGLE_SPAN=360 # Must be 0-360
SUBDIVS=3

# euler_to_quaternion: print QX QY QZ QW for given roll, pitch, yaw (degrees)
euler_to_quaternion() {
  local roll_deg=$1
  local pitch_deg=$2
  local yaw_deg=$3

  # Pi in bc calculator
  local pi=$(echo "4 * a(1)" | bc -l)

  # Degrees to radians
  local roll_rad=$(echo "$roll_deg * $pi / 180" | bc -l)
  local pitch_rad=$(echo "$pitch_deg * $pi / 180" | bc -l)
  local yaw_rad=$(echo "$yaw_deg * $pi / 180" | bc -l)

  # Half-angles
  local hr=$(echo "$roll_rad / 2" | bc -l)
  local hp=$(echo "$pitch_rad / 2" | bc -l)
  local hy=$(echo "$yaw_rad / 2" | bc -l)

  # Trigonometry
  local cr=$(echo "c($hr)" | bc -l)
  local sr=$(echo "s($hr)" | bc -l)
  local cp=$(echo "c($hp)" | bc -l)
  local sp=$(echo "s($hp)" | bc -l)
  local cy=$(echo "c($hy)" | bc -l)
  local sy=$(echo "s($hy)" | bc -l)

  # Compute quaternion
  local qw=$(echo "$cr * $cp * $cy + $sr * $sp * $sy" | bc -l)
  local qx=$(echo "$sr * $cp * $cy - $cr * $sp * $sy" | bc -l)
  local qy=$(echo "$cr * $sp * $cy + $sr * $cp * $sy" | bc -l)
  local qz=$(echo "$cr * $cp * $sy - $sr * $sp * $cy" | bc -l)

  # Output space-separated
  printf "%.6f %.6f %.6f %.6f\n" "$qx" "$qy" "$qz" "$qw"
}

# Start

# Calculate single subdivision
ANGLE_SUBD=$(( ${ANGLE_SPAN} / ${SUBDIVS} ))

ITER=${SUBDIVS}
# Skip 360deg angle (equal to 0deg)
if [[ "${ANGLE_SPAN}" == "360" ]]; then
  echo "Screenshots at 360deg angle will be skipped."
  ITER=$((SUBDIVS - 1))
fi

for x in $(seq 0 "$ITER"); do
  for y in $(seq 0 "$ITER"); do
    ANGLE_X=$(( x * ANGLE_SUBD ))
    ANGLE_Y=$(( y * ANGLE_SUBD ))
    ANGLE_Z=0
    quat=( $(euler_to_quaternion $ANGLE_X $ANGLE_Y $ANGLE_Z) )

    QX=${quat[0]}
    QY=${quat[1]}
    QZ=${quat[2]}
    QW=${quat[3]}
    echo "Set Head Rotation: QX=$QX QY=$QY QZ=$QZ QW=$QW"

    # Inject head pose into Monado
    ${CLIENT_MONADO} <<EOF
set head position ${PX} ${PY} ${PZ}
set head rotation ${QX} ${QY} ${QZ} ${QW}
EOF

    # Allow the system to stabilize and wait render frame to load
    sleep ${WAIT_TIME}

    # Capture the composited window
    grim -g "0,0 ${VIEW_WIDTH}x${VIEW_HEIGHT}" "${OUTDIR}/screenshot-${ANGLE_X}_${ANGLE_Y}_${ANGLE_Z}deg.png"

    # Pause before next iteration
    sleep 1
  done
done

echo "Screenshots of ${ANGLE_SPAN}deg sequence saved in ${OUTDIR}/"
