#IMG_PATH_BASE:     "gs://hive-tomography/pilot11-tiles/rough_montaged_nocrop_22"
#DST_PATH_BASE:     "gs://hive-tomography/pilot11-tiles/rough_montaged_nocrop_enc_22"
#INTERMEDIARY_PATH: "gs://tmp_2w/hive-tomography/pilot11-tiles/rough_montaged_nocrop_enc_22"

#IMG_RES: [1, 1, 1]

#IMG_SIZE: [786432, 262144, 1]

#MODELS: #GENERAL_ENC_MODELS

#OFFSETS: ["(0,0)", "(0,1)", "(1,0)", "(1,1)"]

#TEST_LOCAL: false

#BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, 0]
	end_coord: [786432, 262144, 1]
	resolution: [1, 1, 1]
}

#XY_ENC_RES: [8, 16, 32, 64, 128, 256, 512]

#PROCESS_CROP_PAD: [16, 16, 0] // 16 pix was okay for 1um model

#SRC_TMPL: {
	"@type": "build_cv_layer"
	path:    _
}

#TOP_LEVEL_FLOW: _ | *#GCP_FLOW
if #TEST_LOCAL {
	#TOP_LEVEL_FLOW: #GCP_FLOW
}

#LOCAL_FLOW: {
	"@type":   "mazepa.execute_locally"
	num_procs: 1
	semaphores_spec: {
		read:  num_procs
		write: num_procs
		cuda:  1
		cpu:   num_procs
	}
	target: _
}

#GCP_FLOW: {
	"@type":               "mazepa.execute_on_gcp_with_sqs"
	worker_cluster_region: "us-east1"
	worker_image:          "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-hive-5"
	worker_resources: {
		memory:           "18560Mi" // sized for n1-highmem-4
		"nvidia.com/gpu": "1"
	}
	worker_cluster_project: "zetta-research"
	worker_cluster_name:    "zutils-x3"
	worker_replicas:        128
	local_test:             false
	debug:                  false
	num_procs:              2
	target:                 _
	semaphores_spec: {
		"read":  2
		"cpu":   2
		"cuda":  1
		"write": 2
	}
}
#TOP_LEVEL_FLOW & {
	target: {
		"@type": "mazepa.concurrent_flow"
		stages: [
			for offset in #OFFSETS for xy in #XY_ENC_RES {
				let model = #MODELS["\(xy)"]
				let bbox_ = #BBOX
				#ENC_FLOW_TMPL & {
					bbox: bbox_
					op: fn: model_path:  model.path
					op: fn: ds_factor:   model.res_change_mult[0]
					op: fn: tile_pad_in: model.res_change_mult[0] * #PROCESS_CROP_PAD[0]
					op: fn: tile_size:   model.res_change_mult[0] * model.process_chunk_sizes[1][0]
					op: res_change_mult: model.res_change_mult
					op: crop_pad:        #PROCESS_CROP_PAD
					op_kwargs: src: path: "\(#IMG_PATH_BASE)/\(offset)"
					dst: path: "\(#DST_PATH_BASE)/\(offset)"
					processing_chunk_sizes: model.process_chunk_sizes
					processing_crop_pads: [[0, 0, 0], #PROCESS_CROP_PAD]
					dst_resolution: [xy, xy, #IMG_RES[2]]
				}
			},
		]
	}
}

#ENC_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	bbox:    _
	//level_intermediaries_dirs: [null, "file://."]
	level_intermediaries_dirs: [#INTERMEDIARY_PATH, "file://."]
	// skip_intermediaries: true
	op: {
		"@type": "VolumetricCallableOperation"
		fn: {
			"@type":     "BaseCoarsener"
			model_path:  _
			ds_factor:   _
			tile_pad_in: _
			tile_size:   _
		}
		fn_semaphores: ["cuda"]
		res_change_mult: _
		crop_pad:        _ | *#PROCESS_CROP_PAD
	}
	op_kwargs: {
		src: #SRC_TMPL
	}
	dst_resolution:         _
	processing_chunk_sizes: _
	processing_crop_pads:   _
	// expand_bbox_resolution: true
	dst: #DST_TMPL
}

#CNS_ENC_MODELS: {
	// Adapted from https://github.com/ZettaAI/zetta_utils/blob/nkem/zfish-enc/specs/nico/inference/cns/0_encoding_cns/CNS_encoding_pyramid.cue#L47-L88
	"10": {
		path: "gs://zetta-research-nico/training_artifacts/base_encodings/gamma_low0.75_high1.5_prob1.0_tile_0.0_0.2_lr0.00002_post1.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [1, 1, 1] // 0 3-3: 32-32
		process_chunk_sizes: [[8192, 8192, 8], [4096, 4096, 1]]
	}
	"40": {
		path: "gs://zetta-research-nico/training_artifacts/base_encodings/gamma_low0.75_high1.5_prob1.0_tile_0.0_0.2_lr0.00002_post1.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [1, 1, 1] // 0 3-3: 32-32
		process_chunk_sizes: [[4096, 4096, 6], [4096, 4096, 1]]
	}
	"80": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/3_M3_M4_conv1_unet3_lr0.0001_equi0.5_post1.6_fmt0.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [2, 2, 1] // 1 3-4: 32-64
		process_chunk_sizes: [[2048, 2048, 4], [2048, 2048, 1]]
	}
	"160": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/3_M3_M5_conv2_unet2_lr0.0001_equi0.5_post1.4_fmt0.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [4, 4, 1] // 2 3-5: 32-128
		process_chunk_sizes: [[1024, 1024, 4], [1024, 1024, 1]]
	}
	"320": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/4_M3_M6_conv3_unet1_lr0.0001_equi0.5_post1.1_fmt0.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [8, 8, 1] // 3 3-6: 32-256
		process_chunk_sizes: [[512, 512, 4], [512, 512, 1]]
	}
	"640": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/5_M3_M7_conv4_lr0.0001_equi0.5_post1.03_fmt0.8_cns_all/epoch=0-step=1584-backup.ckpt.model.spec.json"
		res_change_mult: [16, 16, 1] // 4 3-7: 32-512
		process_chunk_sizes: [[512, 512, 1], [256, 256, 1]]
	}
	"1280": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/5_M3_M8_conv5_lr0.0001_equi0.5_post1.03_fmt0.8_cns_all/last.ckpt.static-1.13.1+cu117-model.jit"
		res_change_mult: [32, 32, 1] // 4 3-7: 32-
		process_chunk_sizes: [[512, 512, 1], [128, 128, 1]]
	}
	"2560": {
		path: "gs://zetta-research-nico/training_artifacts/base_coarsener_cns/5_M4_M9_conv5_lr0.00002_equi0.5_post1.1_fmt0.8_cns_all/last.ckpt.model.spec.json"
		res_change_mult: [32, 32, 1] // 4 3-7: 32-
		process_chunk_sizes: [[512, 512, 1], [128, 128, 1]]
	}
}

#GENERAL_ENC_MODELS: {
	"8": {
		path: "gs://zetta-research-nico/training_artifacts/general_encoder_loss/4.0.1_M3_M3_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.03_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [1, 1, 1] //
		process_chunk_sizes: [[2048, 2048, 1], [1024, 1024, 1]]
	}
	"16": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/4.0.0_M3_M4_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.06_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [2, 2, 1] //
		process_chunk_sizes: [[1024, 1024, 1], [512, 512, 1]]
	}
	"32": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/4.0.0_M3_M5_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.08_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [4, 4, 1] //
		process_chunk_sizes: [[1024, 1024, 1], [512, 512, 1]]
	}
	"64": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/4.4.0_M3_M6_C1_lr0.0002_locality1.0_similarity0.0_l10.05-0.12_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [8, 8, 1] //
		process_chunk_sizes: [[512, 512, 1], [256, 256, 1]]
	}
	"128": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/4.0.0_M3_M7_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.12_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [16, 16, 1] // 2
		process_chunk_sizes: [[512, 512, 1], [128, 128, 1]]
	}
	"256": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/1.0.0_M3_M8_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.12_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [32, 32, 1]
		process_chunk_sizes: [[256, 256, 1], [64, 64, 1]]
	}
	"512": {
		path: "gs://zetta-research-nico/training_artifacts/general_coarsener_loss/1.0.2_M4_M9_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.12_N1x4/last.ckpt.model.spec.json"
		res_change_mult: [32, 32, 1]
		process_chunk_sizes: [[128, 128, 1], [32, 32, 1]]
	}
}

#DST_TMPL: {
	"@type": "build_cv_layer"
	path:    _
	info_add_scales_ref: {
		resolution: #IMG_RES
		size:       #IMG_SIZE
		chunk_sizes: [[512, 512, 1]]
		encoding: "raw"
		voxel_offset: [0, 0, 0]
	}
	info_add_scales: [
		for xy in #XY_ENC_RES {
			[xy, xy, #IMG_RES[2]]
		},
	]
	info_add_scales_mode: "merge"
	info_field_overrides: {
		type:         "image"
		num_channels: 1
		data_type:    "int8"
		type:         "image"
	}
	on_info_exists: "overwrite"
	write_procs: [{"@type": "CLAHEProcessor"}]
}
