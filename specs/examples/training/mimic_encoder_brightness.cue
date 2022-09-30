#EXP_NAME:      "mimic_encodings"
#EXP_VERSION:   "tile_aug"
#TRAINING_ROOT: "gs://tmp_2w/nkem/training_artifacts"

//#MODEL_CKPT: "\(#TRAINING_ROOT)/\(#EXP_NAME)/\(#EXP_VERSION)/last.ckpt"
#MODEL_CKPT: null // Set to a path to only load the net weights

#FULL_STATE_CKPT: null // Set to a path to resume from the WHOLE STATE (weights+hparams+optimizer)

#IMG_CV: "https://storage.googleapis.com/fafb_v15_aligned/v0/img/img"
#ENC_CV: "https://storage.googleapis.com/fafb_v15_aligned/v0/experiments/emb_fp32/baseline_downs_emb_m2_m4_x0"

"@type":   "lightning_train"
ckpt_path: #FULL_STATE_CKPT
regime: {
	"@type": "NaiveSupervised"
	lr:      4e-4
	model: {
		"@type": "load_weights_file"
		model: {
			"@type": "ArtificerySpec"
			spec: {
				"type": "convblock"
				"arch_desc": {
					"fms": [1, 32, 32, 32, 32, 1]
					"skips": {"1": 4}
					"k": 5
				}
			}
		}
		ckpt_path: #MODEL_CKPT
		component_names: [
			"model",
		]
	}
}
trainer: {
	"@type":            "ZettaDefaultTrainer"
	accelerator:        "gpu"
	devices:            1
	max_epochs:         1
	default_root_dir:   #TRAINING_ROOT
	experiment_name:    #EXP_NAME
	experiment_version: #EXP_VERSION
	log_every_n_steps:  100
	val_check_interval: 100
	checkpointing_kwargs: {
		update_every_n_secs: 60
		backup_every_n_secs: 900
	}
	profiler: "simple"
}
//dset specs
#dset_settings: {
	"@type": "LayerDataset"
	layer: {
		"@type": "LayerSet"
		layers: {
			data_in: {
				"@type": "CVLayer"
				path:    #IMG_CV
				//cv_kwargs: {cache: true}
				read_postprocs: [
					{
						"@type": "rearrange"
						"@mode": "partial"
						pattern: "c x y 1 -> c 1 x y"
					},
					{
						"@type": "divide"
						"@mode": "partial"
						value:       255.0
					},
					{
						"@type": "square_tile_pattern_aug"
						"@mode": "partial"
						prob:    1.0
						tile_size: {
							"@type": "uniform_dist"
							low:     64
							high:    1024
						}
						tile_stride: {
							"@type": "uniform_dist"
							low:     64
							high:    1024
						}
						max_brightness_change: {
							"@type": "uniform_dist"
							low:     0.2
							high:    0.4
						}
						rotation_degree: {
							"@type": "uniform_dist"
							low:     0
							high:    45
						}
						preserve_data_val: 0.0
						repeats:           3
						device:            "cpu"
					},
					{
						"@type": "add"
						"@mode": "partial"
						value:       -0.5
					},
					{
						"@type": "clamp_values_aug"
						"@mode": "partial"
						prob:    1.0
						low_distr:     -0.5
						high_distr:    0.5
					},
					{
						"@type": "rearrange"
						"@mode": "partial"
						pattern: "c 1 x y -> c x y"
					},
				]
			}
			target: {
				"@type": "CVLayer"
				path:    #ENC_CV
				//cv_kwargs: {cache: true}
				read_postprocs: [
					{
						"@type": "rearrange"
						"@mode": "partial"
						pattern: "c x y 1 -> c x y"
					},
				]
			}
		}
	}
	sample_indexer: {
		"@type": "VolumetricStepIndexer"
		desired_resolution: [64, 64, 40]
		index_resolution: [64, 64, 40]
		sample_size_resolution: [64, 64, 40]
		sample_size: [1024, 1024, 1]
		step_size: [512, 512, 1]
		step_size_resolution: [64, 64, 40]
		bcube: {
			"@type":     "BoundingCube"
			start_coord: _
			end_coord:   _
			resolution: [4, 4, 40]
		}
	}
}

#train_dset: #dset_settings & {
	sample_indexer: {
		bcube: {
			"@type": "BoundingCube"
			start_coord: [80000, 30000, 2000]
			end_coord: [230000, 80000, 2099]
			resolution: [4, 4, 40]
		}
	}
}

#val_dset: #dset_settings & {
	sample_indexer: {
		bcube: {
			"@type": "BoundingCube"
			start_coord: [80000, 30000, 2099]
			end_coord: [230000, 80000, 2100]
			resolution: [4, 4, 40]
		}
	}
}
train_dataloader: {
	"@type":     "TorchDataLoader"
	batch_size:  1
	shuffle:     true
	num_workers: 8
	dataset:     #train_dset
}
val_dataloader: {
	"@type":     "TorchDataLoader"
	batch_size:  1
	shuffle:     false
	num_workers: 8
	dataset:     #val_dset
}
