extends Node

const NUM_PARTICLES = 10
const MAX_ITERATIONS = 100
const INERTIA_WEIGHT = 0.7
const COGNITIVE_WEIGHT = 1.4
const SOCIAL_WEIGHT = 1.4
const NUM_BONES = 2
const DELAY_BETWEEN_ITERATIONS = 0.1

var particles = []
var velocities = []
var personal_bests = []
var global_best = null
var global_best_fitness = INF

func _ready():
	initialize_pso()
	pso_algorithm()

func initialize_pso():
	for i in range(NUM_PARTICLES):
		var particle = random_particle_position()
		particles.append(particle)
		velocities.append(Vector3.ZERO)
		personal_bests.append(particle)

		var fitness = calculate_fitness(particle)
		if fitness < global_best_fitness:
			global_best_fitness = fitness
			global_best = particle

func pso_algorithm():
	for iteration in range(MAX_ITERATIONS):
		update_particle_positions()
		update_personal_and_global_bests()
		update_particle_velocities()

		yield(get_tree().create_timer(DELAY_BETWEEN_ITERATIONS), "timeout")

func random_particle_position():
	var bones = []
	for i in range(NUM_BONES):
		var position = random_point_on_sphere_surface()
		var radius = rand_range(0, 1)
		bones.append({"position": position, "radius": radius})
	return bones

func random_point_on_sphere_surface():
	var theta = rand_range(0, 2 * PI)
	var phi = acos(2 * rand_range(0, 1) - 1)
	var x = sin(phi) * cos(theta)
	var y = sin(phi) * sin(theta)
	var z = cos(phi)
	return Vector3(x, y, z)

func update_particle_positions():
	for i in range(NUM_PARTICLES):
		for j in range(NUM_BONES):
			particles[i][j].position += velocities[i][j]

const BONE_CONSTRAINTS = [
	{"min_angle": -45, "max_angle": 45},
	{"min_angle": -30, "max_angle": 30},
]

func calculate_fitness(particle_position):
	var fitness = 0.0
	for i in range(NUM_BONES):
		var bone = particle_position[i]
		var angle = rad2deg(bone.position.angle_to(Vector3(0, 1, 0)))

		if angle < BONE_CONSTRAINTS[i].min_angle or angle > BONE_CONSTRAINTS[i].max_angle:
			fitness += INF
		else:
			fitness += pow(bone.position.x, 2) + pow(bone.position.y, 2) + pow(bone.position.z, 2)
	return fitness

func update_personal_and_global_bests():
	for i in range(NUM_PARTICLES):
		var fitness = calculate_fitness(particles[i])
		if fitness < calculate_fitness(personal_bests[i]):
			personal_bests[i] = particles[i]

		if fitness < global_best_fitness:
			global_best_fitness = fitness
			global_best = particles[i]

func update_particle_velocities():
	for i in range(NUM_PARTICLES):
		for j in range(NUM_BONES):
			var inertia = INERTIA_WEIGHT * velocities[i][j]
			var cognitive = COGNITIVE_WEIGHT * rand_range(0, 1) * (personal_bests[i][j].position - particles[i][j].position)
			var social = SOCIAL_WEIGHT * rand_range(0, 1) * (global_best[j].position - particles[i][j].position)

			velocities[i][j] = inertia + cognitive + social
