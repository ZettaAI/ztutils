// R 2UN ACED BLOCK
// INPUTS
#BASE_FOLDER: "gs://zetta_lee_fly_cns_001_alignment_temp/aced"

#IMG_PATH:     "\(#BASE_FOLDER)/coarse_x1/raw_img"
#DEFECTS_PATH: "\(#BASE_FOLDER)/coarse_x1/defect_mask"

//#ENC_PATH:      "gs://sergiy_exp/aced/demo_x0/rigid_to_elastic/raw_img_masked"
#ENC_PATH: "\(#BASE_FOLDER)/coarse_x1/encodings_masked"
#TMP_PATH: "gs://tmp_2w/temporary_layers"

// MODELS
#BASE_ENCODER_PATH: "gs://zetta-research-nico/training_artifacts/base_encodings/gamma_low0.75_high1.5_prob1.0_tile_0.0_0.2_lr0.00002_post1.8_cns_all/last.ckpt.model.spec.json"
#MISD_MODEL_PATH:   "gs://zetta-research-nico/training_artifacts/aced_misd_cns/thr5.0_lr0.00001_z1z2_400-500_2910-2920_more_aligned_unet5_32_finetune_2/last.ckpt.static-2.0.0+cu117-model.jit"

//OUTPUTS
#PAIRWISE_SUFFIX: "try_x0"

#FOLDER:          "\(#BASE_FOLDER)/med_x1/\(#PAIRWISE_SUFFIX)"
#FIELDS_PATH:     "\(#FOLDER)/fields_fwd"
#FIELDS_INV_PATH: "\(#FOLDER)/fields_inv"

#IMGS_WARPED_PATH:      "\(#FOLDER)/imgs_warped"
#WARPED_BASE_ENCS_PATH: "\(#FOLDER)/base_encs_warped"
#MISALIGNMENTS_PATH:    "\(#FOLDER)/misalignments"

#TISSUE_MASK_PATH: "\(#BASE_FOLDER)/tissue_mask"

#AFIELD_PATH:             "\(#FOLDER)/afield\(#RELAXATION_SUFFIX)"
#IMG_ALIGNED_PATH:        "\(#FOLDER)/img_aligned\(#RELAXATION_SUFFIX)"
#IMG_MASK_PATH:           "\(#FOLDER)/img_mask\(#RELAXATION_SUFFIX)"
#AFF_MASK_PATH:           "\(#FOLDER)/aff_mask\(#RELAXATION_SUFFIX)"
#IMG_ALIGNED_MASKED_PATH: "\(#FOLDER)/img_aligned_masked\(#RELAXATION_SUFFIX)"

#MATCH_OFFSETS_PATH: "\(#FOLDER)/match_offsets_z\(#Z_START)_\(#Z_END)"

//#BASE_INFO_CHUNK: [128, 128, 1]
#BASE_INFO_CHUNK: [512, 512, 1]
#RELAX_OUTCOME_CHUNK: [32, 32, 1]
#RELAXATION_FIX:  "last"
#RELAXATION_ITER: 8000
#RELAXATION_LR:   5e-3

#RELAXATION_RIG: 0.5

//BLOCK 0
#Z_START: 0

#Z_END: 4

//BLOCK 1
//#Z_START: 451

//#Z_END: 901
//#Z_END: 975
//#Z_START: 2000

//#Z_END: 2050
//#Z_START: 1500
//#Z_END: 2000

//#Z_START: 599
//#Z_END:   746

//#RELAXATION_SUFFIX: "_fix\(#RELAXATION_FIX)_iter\(#RELAXATION_ITER)_rig\(#RELAXATION_RIG)_z\(#Z_START)-\(#Z_END)"
#RELAXATION_SUFFIX: "_debug_x2"
#RELAXATION_RESOLUTION: [1024, 1024, 45]

#BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, #Z_START]
	end_coord: [512, 512, #Z_END]
	resolution: [512, 512, 45]
}

#TITLE: #PAIRWISE_SUFFIX
#MAKE_NG_URL: {
	"@type": "make_ng_link"
	title:   #TITLE
	position: [50000, 60000, #Z_START + 1]
	scale_bar_nm: 30000
	layers: [
		["precoarse_img", "image", "precomputed://\(#IMG_PATH)"],
		["-1 \(#PAIRWISE_SUFFIX)", "image", "precomputed://\(#IMGS_WARPED_PATH)/-1"],
		//["aligned masked \(#RELAXATION_SUFFIX)", "image", "precomputed://\(#IMG_ALIGNED_MASKED_PATH)"],
		["aligned \(#RELAXATION_SUFFIX)", "image", "precomputed://\(#IMG_ALIGNED_PATH)"],
		["aligned \(#RELAXATION_SUFFIX) -2", "image", "precomputed://\(#IMG_ALIGNED_PATH)"],
	]
}

#NOT_FIRST_SECTION_BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, #Z_START + 1]
	end_coord: [ 2048, 2048, #Z_END]
	resolution: [512, 512, 45]
}

#FIRST_SECTION_BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, #Z_START]
	end_coord: [2048, 2048, #Z_START + 1]
	resolution: [512, 512, 45]
}

#STAGES: [
	#STAGE_TMPL & {
		dst_resolution: [2048, 2048, 45]
		fn: {
			sm:       100
			num_iter: 1000
			lr:       0.015
		}
		shrink_processing_chunk: true
		expand_bbox_processing:             false
	},
	#STAGE_TMPL & {
		dst_resolution: [1024, 1024, 45]
		fn: {
			sm:       100
			num_iter: 1000
			lr:       0.015
		}
		shrink_processing_chunk: true
		expand_bbox_processing:             false
	},
	#STAGE_TMPL & {
		dst_resolution: [512, 512, 45]

		fn: {
			sm:       50
			num_iter: 700
			lr:       0.015
		}
		shrink_processing_chunk: true
		expand_bbox_processing:             false
	},
	#STAGE_TMPL & {
		dst_resolution: [256, 256, 45]

		fn: {
			sm:       50
			num_iter: 700
			lr:       0.03
		}
		shrink_processing_chunk: true
		expand_bbox_processing:             false
	},
	#STAGE_TMPL & {
		dst_resolution: [128, 128, 45]

		fn: {
			sm:       10
			num_iter: 500
			lr:       0.05
		}

	},
	#STAGE_TMPL & {
		dst_resolution: [1024, 1024, 45]
		fn: {
			sm:       10
			num_iter: 1000
			lr:       0.015
		}

	},
	#STAGE_TMPL & {
		dst_resolution: [512, 512, 45]

		fn: {
			sm:       10
			num_iter: 700
			lr:       0.015
		}

	},
	#STAGE_TMPL & {
		dst_resolution: [256, 256, 45]

		fn: {
			sm:       10
			num_iter: 700
			lr:       0.03
		}

	},
	#STAGE_TMPL & {
		dst_resolution: [128, 128, 45]

		fn: {
			sm:       10
			num_iter: 500
			lr:       0.05
		}

	},
	#STAGE_TMPL & {
		dst_resolution: [64, 64, 45]

		fn: {
			sm:       10
			num_iter: 300
			lr:       0.1
		}

	},

	#STAGE_TMPL & {
		dst_resolution: [32, 32, 45]

		fn: {
			sm:       10
			num_iter: 200
			lr:       0.1
		}

	},
]

#STAGE_TMPL: {
	"@type":        "ComputeFieldStage"
	dst_resolution: _

	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 2, 1024 * 2, 1]]
	max_reduction_chunk_sizes: [1024 * 8, 1024 * 8, 1]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]

	processing_blend_pads: [[0, 0, 0], [0, 0, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]
	expand_bbox_processing:             bool | *true
	shrink_processing_chunk: bool | *false

	fn: {
		"@type":  "align_with_online_finetuner"
		"@mode":  "partial"
		sm:       _
		num_iter: _
		lr?:      _
	}
}

#CF_FLOW_TMPL: {
	"@type":     "build_compute_field_multistage_flow"
	bbox:        #NOT_FIRST_SECTION_BBOX
	stages:      #STAGES
	src_offset?: _
	tgt_offset?: _
	offset_resolution: [4, 4, 45]
	src: {
		"@type": "build_ts_layer"
		path:    #ENC_PATH
	}
	tgt: {
		"@type": "build_ts_layer"
		path:    #ENC_PATH
	}
	dst: {
		"@type": "build_cv_layer"
		path:    _
		//info_reference_path: #IMG_PATH
		//info_field_overrides: {
		//num_channels: 2
		//data_type:    "float32"
		//}
		//info_chunk_size: #BASE_INFO_CHUNK
		//on_info_exists:  "overwrite"
	}
	tmp_layer_dir: _
	tmp_layer_factory: {
		"@type":             "build_cv_layer"
		"@mode":             "partial"
		info_reference_path: dst.path
		//info_reference_path: #IMG_PATH
		//info_field_overrides: {
		//  num_channels: 2
		//  data_type:    "float32"
		// }
		//info_chunk_size: #BASE_INFO_CHUNK
		//on_info_exists:  "overwrite"
	}
}

#NAIVE_MISD_FLOW: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type": "naive_misd"
		"@mode": "partial"
	}
	processing_chunk_sizes: [[2048, 2048, 1]]
	dst_resolution: #STAGES[len(#STAGES)-1].dst_resolution
	bbox:           #BBOX
	_z_offset:      _
	src: {
		"@type": "build_ts_layer"
		path:    "\(#IMGS_WARPED_PATH)/\(_z_offset)"
	}
	tgt: {
		"@type": "build_ts_layer"
		path:    #IMG_PATH
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                "\(#MISALIGNMENTS_PATH)/\(_z_offset)"
		info_reference_path: #IMG_PATH
		info_chunk_size:     #BASE_INFO_CHUNK
		on_info_exists:      "overwrite"
		write_procs: [
		]
	}
}

#WARP_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	op: {
		"@type": "WarpOperation"
		mode:    _
	}
	expand_bbox_processing: true
	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 2, 1024 * 2, 1]]
	max_reduction_chunk_sizes: [1024 * 8, 1024 * 8, 1]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]

	//chunk_size: [512, 512, 1]
	bbox:           #BBOX
	dst_resolution: _ | *#STAGES[len(#STAGES)-1].dst_resolution
	src: {
		"@type":      "build_ts_layer"
		path:         _
		read_procs?:  _
		index_procs?: _ | *[]
	}
	field: {
		"@type":            "build_ts_layer"
		path:               _
		data_resolution:    _ | *null
		interpolation_mode: "field"
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: #IMG_PATH
		on_info_exists:      "overwrite"
		write_procs?:        _
		index_procs?:        _ | *[]
	}
}

#INVERT_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {"@type": "invert_field", "@mode": "partial"}
	expand_bbox_processing: true
	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 2, 1024 * 2, 1]]
	max_reduction_chunk_sizes: [1024 * 8, 1024 * 8, 1]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]

	dst_resolution: #STAGES[len(#STAGES)-1].dst_resolution
	bbox:           #BBOX
	src: {
		"@type": "build_ts_layer"
		path:    _
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: src.path
		info_chunk_size:     #BASE_INFO_CHUNK
		on_info_exists:      "overwrite"
	}
}

#ENCODE_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type":    "BaseEncoder"
		model_path: #BASE_ENCODER_PATH
	}
	expand_bbox_processing: true

	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 1, 1024 * 1, 1]]
	max_reduction_chunk_sizes: [1024 * 8, 1024 * 8, 1]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]

	dst_resolution: #STAGES[len(#STAGES)-1].dst_resolution
	bbox:           #BBOX
	_z_offset:      _
	src: {
		"@type": "build_ts_layer"
		path:    "\(#IMGS_WARPED_PATH)/\(_z_offset)"
	}
	dst: {
		"@type": "build_cv_layer"
		path:    "\(#IMGS_WARPED_PATH)/\(_z_offset)_enc"
		//path:                #MATCH_OFFSETS_PATH
		info_reference_path: #IMG_PATH
		on_info_exists:      "overwrite"
		info_field_overrides: {
			data_type: "int8"
		}
	}
}

#MISD_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type":    "MisalignmentDetector"
		model_path: #MISD_MODEL_PATH
	}
	expand_bbox_processing: true

	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 2, 1024 * 2, 1]]
	max_reduction_chunk_sizes: [1024 * 8, 1024 * 8, 1]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]

	dst_resolution: #STAGES[len(#STAGES)-1].dst_resolution
	bbox:           #BBOX
	_z_offset:      _
	src: {
		"@type": "build_ts_layer"
		path:    "\(#IMGS_WARPED_PATH)/\(_z_offset)_enc"
	}
	tgt: {
		"@type": "build_ts_layer"
		path:    #ENC_PATH
	}
	dst: {
		"@type": "build_cv_layer"
		path:    "\(#MISALIGNMENTS_PATH)/\(_z_offset)"
		//path:                #MATCH_OFFSETS_PATH
		info_reference_path: #IMG_PATH
		on_info_exists:      "overwrite"
		write_procs: [

		]
	}
}

#Z_OFFSETS: [-1, -2]
#JOINT_OFFSET_FLOW: {
	"@type": "mazepa.concurrent_flow"
	stages: [
		for z_offset in #Z_OFFSETS {
			"@type": "mazepa.concurrent_flow"
			stages: [
				{
					"@type": "mazepa.seq_flow"
					stages: [
						#CF_FLOW_TMPL & {
							dst: path: "\(#FIELDS_PATH)/\(z_offset)"
							tmp_layer_dir: "\(#FIELDS_PATH)/\(z_offset)/tmp"
							tgt_offset: [0, 0, z_offset]
						},
						#INVERT_FLOW_TMPL & {
							src: path: "\(#FIELDS_PATH)/\(z_offset)"
							dst: path: "\(#FIELDS_INV_PATH)/\(z_offset)"
						},
						#WARP_FLOW_TMPL & {
							op: mode:  "img"
							dst: path: "\(#IMGS_WARPED_PATH)/\(z_offset)"
							src: path: #IMG_PATH
							src: index_procs: [
								{
									"@type": "VolumetricIndexTranslator"
									offset: [0, 0, z_offset]
									resolution: [4, 4, 45]
								},
							]
							field: path: "\(#FIELDS_INV_PATH)/\(z_offset)"
						},
						#ENCODE_FLOW_TMPL & {
							_z_offset: z_offset
						},
						#MISD_FLOW_TMPL & {
							_z_offset: z_offset
						}
						// #NAIVE_MISD_FLOW & {
						//  _z_offset: z_offset
						// },,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
					]
				},
			]
		},
	]
}

#CREATE_TISSUE_MASK: {
	"@type": "build_subchunkable_apply_flow"
	bbox:    #BBOX
	fn: {
		"@type":    "lambda"
		lambda_str: "lambda src: (src != 0).byte()"
	}
	processing_chunk_sizes: [[8 * 1024, 1024 * 8, 1]]
	dst_resolution: #STAGES[len(#STAGES)-1].dst_resolution

	src: {
		"@type": "build_ts_layer"
		path:    #ENC_PATH
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                #TISSUE_MASK_PATH
		info_reference_path: src.path
		info_field_overrides: {
			data_type: "uint8"
		}
		on_info_exists: "overwrite"
	}
}

#MATCH_OFFSETS_FLOW: {
	"@type": "build_subchunkable_apply_flow"
	bbox:    #BBOX
	op: {
		"@type": "AcedMatchOffsetOp"
	}
	processing_chunk_sizes: [[128, 128, #Z_END - #Z_START]]
	processing_crop_pads: [[32, 32, 0]]
	dst_resolution: #RELAXATION_RESOLUTION
	max_dist:       2

	tissue_mask: {
		"@type": "build_ts_layer"
		path:    #TISSUE_MASK_PATH
	}
	misalignment_masks: {
		for offset in #Z_OFFSETS {
			"\(offset)": {
				"@type": "build_ts_layer"
				path:    "\(#MISALIGNMENTS_PATH)/\(offset)"
				read_procs: [
					{
						"@type": "compare"
						"@mode": "partial"
						mode:    ">="
						value:   127
					},
					{
						"@type": "to_uint8"
						"@mode": "partial"
					},
				]
			}
		}
	}
	pairwise_fields: {
		for offset in #Z_OFFSETS {
			"\(offset)": {
				"@type": "build_ts_layer"
				path:    "\(#FIELDS_PATH)/\(offset)"
			}
		}
	}
	pairwise_fields_inv: {
		for offset in #Z_OFFSETS {
			"\(offset)": {
				"@type": "build_ts_layer"
				path:    "\(#FIELDS_INV_PATH)/\(offset)"
			}
		}
	}
	dst: {
		"@type": "build_volumetric_layer_set"
		layers: {
			match_offsets: {
				"@type":             "build_cv_layer"
				path:                #MATCH_OFFSETS_PATH
				info_reference_path: #IMG_PATH
				info_chunk_size:     #RELAX_OUTCOME_CHUNK
				on_info_exists:      "overwrite"
				write_procs: [
					{"@type": "to_uint8", "@mode": "partial"},
				]
			}
			img_mask: {
				"@type":             "build_cv_layer"
				path:                "\(#MATCH_OFFSETS_PATH)/img_mask"
				info_reference_path: #IMG_PATH
				info_chunk_size:     #RELAX_OUTCOME_CHUNK
				on_info_exists:      "overwrite"
				write_procs: [
					{"@type": "to_uint8", "@mode": "partial"},
				]
			}
			aff_mask: {
				"@type":             "build_cv_layer"
				path:                "\(#MATCH_OFFSETS_PATH)/aff_mask"
				info_reference_path: #IMG_PATH
				info_chunk_size:     #RELAX_OUTCOME_CHUNK
				on_info_exists:      "overwrite"
				write_procs: [
					{"@type": "to_uint8", "@mode": "partial"},
				]
			}
			sector_length_before: {
				"@type":             "build_cv_layer"
				path:                "\(#MATCH_OFFSETS_PATH)/sl_before"
				info_reference_path: #IMG_PATH
				info_chunk_size:     #RELAX_OUTCOME_CHUNK
				on_info_exists:      "overwrite"
				write_procs: [
					{"@type": "to_uint8", "@mode": "partial"},
				]
			}
			sector_length_after: {
				"@type":             "build_cv_layer"
				path:                "\(#MATCH_OFFSETS_PATH)/sl_after"
				info_reference_path: #IMG_PATH
				info_chunk_size:     #RELAX_OUTCOME_CHUNK
				on_info_exists:      "overwrite"
				write_procs: [
					{"@type": "to_uint8", "@mode": "partial"},
				]
			}
		}
	}
}

#RELAX_FLOW: {
	"@type": "build_subchunkable_apply_flow"
	//op: {
	//               "@type": "AcedRelaxationOp"
	//              }
	fn: {
		"@type":    "lambda"
		lambda_str: "lambda yo: yo"
	}
	expand_bbox_processing:    true
	dst_resolution: #RELAXATION_RESOLUTION
	bbox:           #BBOX

	processing_chunk_sizes: [[32, 32, #Z_END - #Z_START]]
	max_reduction_chunk_sizes: [32, 32, #Z_END - #Z_START]
	processing_crop_pads: [[48, 48, 0]]
	processing_blend_pads: [[8, 8, 0]]
	level_intermediaries_dirs: [#TMP_PATH]
	//              processing_chunk_sizes: [[32, 32, #Z_END - #Z_START], [28, 28, #Z_END - #Z_START]]
	//              max_reduction_chunk_sizes: [128, 128, #Z_END - #Z_START]
	//              processing_crop_pads: [[0, 0, 0], [16, 16, 0]]
	//              processing_blend_pads: [[12, 12, 0], [12, 12, 0]]
	//level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]
	yo: {
		"@type": "build_ts_layer"
		path:    "\(#FIELDS_PATH)/-1"
		read_procs: [
			{
				"@type": "compare"
				"@mode": "partial"
				mode:    "!="
				value:   3.14
			},
			{
				"@type": "to_float32"
				"@mode": "partial"
			},

		]
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                #AFIELD_PATH
		info_reference_path: #IMG_PATH

		info_field_overrides: {
			num_channels: 2
			data_type:    "float32"
		}
		info_chunk_size: #RELAX_OUTCOME_CHUNK
		on_info_exists:  "overwrite"
	}
}

#DOWNSAMPLE_FLOW_TMPL: {
	"@type":     "build_subchunkable_apply_flow"
	expand_bbox_processing: true
	processing_chunk_sizes: [[1024 * 8, 1024 * 8, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [0, 0, 0]]
	level_intermediaries_dirs: [#TMP_PATH, "~/.zutils/tmp"]
	dst_resolution: _
	op: {
		"@type": "InterpolateOperation"
		mode:    _
		res_change_mult: [2, 2, 1]
	}
	bbox: #BBOX
	src: {
		"@type":    "build_ts_layer"
		path:       _
		read_procs: _ | *[]
	}
	dst: {
		"@type": "build_cv_layer"
		path:    src.path
	}
}

#DOWNSAMPLE_FLOW: {
	"@type": "mazepa.concurrent_flow"
	stages: [
		for z_offset in #Z_OFFSETS {
			"@type": "mazepa.concurrent_flow"
			stages: [
				// {
				//  "@type": "mazepa.seq_flow"
				//  stages: [
				//   for res in [64, 128, 256, 512, 1024] {
				//    #DOWNSAMPLE_FLOW_TMPL & {
				//     op: mode:  "img" // not thresholded due to subhcunkable bug
				//     src: path: "\(#MISALIGNMENTS_PATH)/\(z_offset)"
				//     // src: read_procs: [
				//     //  {"@type": "filter_cc", "@mode": "partial", mode: "keep_large", thr: 20},
				//     // ]
				//     dst_resolution: [res, res, 45]
				//    }
				//   },
				//  ]
				// },
				{
					"@type": "mazepa.seq_flow"
					stages: [
						for res in [64, 128, 256, 512, 1024] {
							#DOWNSAMPLE_FLOW_TMPL & {
								op: mode:  "mask"
								src: path: #TISSUE_MASK_PATH
								dst_resolution: [res, res, 45]
							}
						},
					]
				},
				// {
				//  "@type": "mazepa.seq_flow"
				//  stages: [
				//   for res in [64, 128, 256, 512, 1024] {
				//    #DOWNSAMPLE_FLOW_TMPL & {
				//     op: mode:  "field"
				//     src: path: "\(#FIELDS_PATH)/\(z_offset)"
				//     dst_resolution: [res, res, 45]
				//    }
				//   },
				//  ]
				// },
				// {
				//  "@type": "mazepa.seq_flow"
				//  stages: [
				//   for res in [64, 128, 256, 512, 1024] {
				//    #DOWNSAMPLE_FLOW_TMPL & {
				//     op: mode:  "field"
				//     src: path: "\(#FIELDS_INV_PATH)/\(z_offset)"
				//     dst_resolution: [res, res, 45]
				//    }
				//   },
				//  ]
				// },
			]
		},
	]
}

#POST_ALIGN_FLOW: {
	"@type": "mazepa.concurrent_flow"
	stages: [
		#WARP_FLOW_TMPL & {
			op: mode:    "img"
			src: path:   #IMG_PATH
			field: path: #AFIELD_PATH
			dst: path:   #IMG_ALIGNED_PATH
			dst_resolution: [32, 32, 45]
			field: data_resolution: #RELAXATION_RESOLUTION
		}
		// #WARP_FLOW_TMPL & {
		//  op: mode:    "mask"
		//  src: path:   "\(#MATCH_OFFSETS_PATH)/img_mask"
		//  field: path: #AFIELD_PATH
		//  dst: path:   #IMG_MASK_PATH
		//  dst_resolution: [32, 32, 45]
		//  field: data_resolution: #RELAXATION_RESOLUTION
		// },
		// #WARP_FLOW_TMPL & {
		//  op: mode:    "mask"
		//  src: path:   "\(#MATCH_OFFSETS_PATH)/aff_mask"
		//  field: path: #AFIELD_PATH
		//  dst: path:   #AFF_MASK_PATH
		//  dst_resolution: [32, 32, 45]
		//  field: data_resolution: #RELAXATION_RESOLUTION
		// },,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

	]
}

#RUN_INFERENCE: {
	"@type": "mazepa.execute_on_gcp_with_sqs"
	//worker_image: "us.gcr.io/zetta-lee-fly-vnc-001/zetta_utils:sergiy_all_p39_x140"
	worker_image: "us.gcr.io/zetta-research/zetta_utils:sergiy_all_p39_x151"
	worker_resources: {
		memory:           "18560Mi"
		"nvidia.com/gpu": "1"
	}
	worker_replicas:        200
	batch_gap_sleep_sec:    1
	do_dryrun_estimation:   true
	local_test:             true
	worker_cluster_name:    "zutils-cns"
	worker_cluster_region:  "us-east1"
	worker_cluster_project: "zetta-lee-fly-vnc-001"
	checkpoint:             "gs://zetta_utils_runs/sergiy/exec-hasty-thick-woodlouse-of-satiation/2023-04-19_154855_783.zstd"

	target: {
		"@type": "mazepa.seq_flow"
		stages: [
			//#JOINT_OFFSET_FLOW,
			//#CREATE_TISSUE_MASK,
			//#DOWNSAMPLE_FLOW,
			//#MATCH_OFFSETS_FLOW,
			#RELAX_FLOW,
			#POST_ALIGN_FLOW,
		]
	}
}

[
	#MAKE_NG_URL,
	#RUN_INFERENCE,
	#MAKE_NG_URL,
]
