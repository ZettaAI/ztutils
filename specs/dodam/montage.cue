import "list"

import "math"

// INPUTS
//#ENCODED_PATH_BASE: "gs://dacey-human-retina-001-montaging/test_tiles_8192full_64crop_6912offset_cns_enc_clahe"
//#ENCODED_PATH_BASE: "gs://dacey-human-retina-001-montaging/rough_aligned_final_cns_enc"
#ENCODED_PATH_BASE: "gs://dacey-human-retina-001-montaging/elastic_rough_aligned_128importcrop_64crop_8x64_uniform_final_cns_enc"

//#ENCODED_PATH_BASE: "gs://dacey-human-retina-001-montaging/test_tiles_8192full_64crop_6912offset_gen_enc_clahe"
#ENCODED_PATH00: "\(#ENCODED_PATH_BASE)/(0,0)"
#ENCODED_PATH01: "\(#ENCODED_PATH_BASE)/(0,1)"
#ENCODED_PATH10: "\(#ENCODED_PATH_BASE)/(1,0)"
#ENCODED_PATH11: "\(#ENCODED_PATH_BASE)/(1,1)"

//#IMG_PATH_BASE: "gs://dacey-human-retina-001-montaging/test_tiles_8192full_384crop_6912offset"
#IMG_PATH_BASE: "gs://dacey-human-retina-001-montaging/elastic_rough_aligned_384importcrop_64crop_8x64_uniform_final"

//#IMG_PATH_BASE: "gs://dacey-human-retina-001-montaging/rough_aligned_final"
#IMG_PATH00: "\(#IMG_PATH_BASE)/(0,0)"
#IMG_PATH01: "\(#IMG_PATH_BASE)/(0,1)"
#IMG_PATH10: "\(#IMG_PATH_BASE)/(1,0)"
#IMG_PATH11: "\(#IMG_PATH_BASE)/(1,1)"

#IMG_RES: [5, 5, 50]

#IMG_SIZE: [65536, 65536, 16000]

#FOLDER: "gs://dacey-human-retina-001-montaging/montage_prod_384croprender_128cropenc_sanity"

#SKIP_ENCODE: true
#SKIP_MISD:   true
#TEST_SMALL:  true
#TEST_LOCAL:  true

#CLUSTER_NUM_WORKERS: 1000

#NUM_ITER: 1000
//#NUM_ITER: 0

// Use CNS model for these steps instead of zfish
//#STAGE_TMPL_160: src: path: #ENC_PATH_CNS
//#STAGE_TMPL_160: tgt: path: #ENC_PATH_CNS

// OUTPUTS
#COMBINED_FIELDS_PATH01: "\(#FOLDER)/fields_fwd_01"
#COMBINED_FIELDS_PATH11: "\(#FOLDER)/fields_fwd_11"
#COMBINED_FIELDS_PATH1:  "\(#FOLDER)/fields_fwd_1"
#FIELDS_INV_PATH:        "\(#FOLDER)/fields_inv"

//#IMG_WARPED_PATH:      "\(#FOLDER)/imgs_warped_1000_250_25_5_1_4000iter_320r-20"
#WARPED_BASE_ENCS_PATH:   "\(#FOLDER)/base_encs_warped"
#MISALIGNMENTS_PATH:      "\(#FOLDER)/misalignments"
#IMG_WARPED_PATH01:       "\(#FOLDER)/img_warped/01"
#IMG_WARPED_PATH11:       "\(#FOLDER)/img_warped/11"
#IMG_WARPED_PATH0:        "\(#FOLDER)/img_warped/0"
#IMG_WARPED_PATH1:        "\(#FOLDER)/img_warped/1"
#IMG_WARPED_PATH1_WARPED: "\(#FOLDER)/img_warped/1_warped"
#IMG_WARPED_PATH_FINAL:   "\(#FOLDER)/img_warped/final"

#ERRORS_PATH0001:   "\(#FOLDER)/errors/0001"
#ERRORS_PATH1011:   "\(#FOLDER)/errors/1011"
#ERRORS_PATH01:     "\(#FOLDER)/errors/01"
#ERRORS_PATH_FINAL: "\(#FOLDER)/errors/final"

#ENCODED_WARPED_PATH01:       "\(#FOLDER)/encoded_warped/01"
#ENCODED_WARPED_PATH11:       "\(#FOLDER)/encoded_warped/11"
#ENCODED_WARPED_PATH0:        "\(#FOLDER)/encoded_warped/0"
#ENCODED_WARPED_PATH1:        "\(#FOLDER)/encoded_warped/1"
#ENCODED_WARPED_PATH1_WARPED: "\(#FOLDER)/encoded_warped/1_warped"
#ENCODED_WARPED_PATH_FINAL:   "\(#FOLDER)/encoded_warped/final"

// PARAMETERS
#Z_OFFSETS: [0]

//#ENCODED_WARP_RES: [20, 20, #IMG_RES[2]]
#ENCODED_WARP_RES: [20, 20, #IMG_RES[2]]
#LOWEST_RES: [1280, 1280, #IMG_RES[2]]
#IMG_WARP_RES: [10, 10, #IMG_RES[2]]
#ERROR_RES: [40, 40, #IMG_RES[2]]

#NUM_ENCODED_WARP_MIPS: math.Log2(#LOWEST_RES[0] / #ENCODED_WARP_RES[0])
#ENCODED_WARP_RESES: [ for i in list.Range(0, #NUM_ENCODED_WARP_MIPS+1, 1) {(#ENCODED_WARP_RES[0] * math.Pow(2, i))}]

//#NUM_WARP_DOWNSAMPLES: math.Log2(#LOWEST_RES[0] / #IMG_WARP_RES[0])
//#DOWNSAMPLE_WARP_RESES: [ for i in list.Range(0, NUM_WARP_DOWNSAMPLES) {(IMG_WARP_RES[0] * math.Pow(2, i+1))}]
#NUM_ERROR_DOWNSAMPLES: math.Log2(#ERROR_RES[0] / #IMG_WARP_RES[0])
#DOWNSAMPLE_ERROR_RESES: [ for i in list.Range(0, #NUM_ERROR_DOWNSAMPLES, 1) {(#IMG_WARP_RES[0] * math.Pow(2, i+1))}]
#NUM_ERROR_FINAL_DOWNSAMPLES: math.Log2(#LOWEST_RES[0] / #ERROR_RES[0])
#DOWNSAMPLE_ERROR_FINAL_RESES: [ for i in list.Range(0, #NUM_ERROR_FINAL_DOWNSAMPLES, 1) {(#ERROR_RES[0] * math.Pow(2, i+1))}]

// 375 - 525 test
#BBOX: {
	"@type": "BBox3D.from_coords"
	if #TEST_SMALL == false {
		start_coord: [0, 0, 60]
		end_coord:  #IMG_SIZE
		resolution: #IMG_RES
	}
	if #TEST_SMALL == true {
		start_coord: [0, 0, 1]
		end_coord: [40960, 40960, 3030]
		resolution: [5, 5, 50]
	}
}

{
	"@type":                "mazepa.execute_on_gcp_with_sqs"
	worker_cluster_region:  "us-east1"
	worker_image:           "us.gcr.io/dacey-human-retina-001/zetta_utils:dodam-montage-zettametroem-6"
	worker_cluster_project: "dacey-human-retina-001"
	worker_cluster_name:    "zutils"
	// worker_image:           "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-8"
	// worker_cluster_project: "zetta-research"
	// worker_cluster_name:    "zutils-x3"
	//               worker_resources: {
	//                memory:           "18560Mi" // sized for n1-highmem-4
	//                "nvidia.com/gpu": "1"
	//               }
	worker_replicas: #CLUSTER_NUM_WORKERS
	local_test:      #TEST_LOCAL
	target:          #JOINT_OFFSET_FLOW
	num_procs:       2
	semaphores_spec: {
		"read":  3
		"cpu":   3
		"cuda":  1
		"write": 3
	}
}

#SKIP_CF:           _ | *false
#SKIP_INVERT_FIELD: _ | *false
#SKIP_WARP:         _ | *false
#SKIP_ENCODE:       _ | *false
#SKIP_MISD:         _ | *false
#TEST_SMALL:        _ | *false
#TEST_LOCAL:        _ | *false

// For testing multiple sections
// #TEST_SECTIONS: [1]
// #JOINT_OFFSET_FLOW: {
//     "@type": "mazepa.concurrent_flow"
//     stages: [
//         for z in #TEST_SECTIONS {
//             let bbox_ = {
//                 "@type": "BBox3D.from_coords"
//                 start_coord: [0, 0, z*160]
//                 end_coord: [262144, 262144, start_coord[2]+160]
//             }
//             #FLOW_ONE_SECTION & {_bbox: bbox_}
//         }
//     ]
// }
// For running one bbox
#JOINT_OFFSET_FLOW: #FLOW_ONE_SECTION & {_bbox: #BBOX}

#RESUME_CF_FLOW: _ | *false

#FLOW_ONE_SECTION: {
	_bbox:   _
	"@type": "mazepa.concurrent_flow"
	stages: [
		for z_offset in #Z_OFFSETS {
			"@type": "mazepa.sequential_flow"
			stages: [
				{"@type": "mazepa.concurrent_flow"
					stages: [
						#COMBINED_FLOW_TMPL & {
							_bbox_:              _bbox
							_encoded_src:        #ENCODED_PATH01
							_encoded_tgt:        #ENCODED_PATH00
							_encoded_src_warped: #ENCODED_WARPED_PATH01
							_encoded_combined:   #ENCODED_WARPED_PATH0
							_src:                #IMG_PATH01
							_tgt:                #IMG_PATH00
							_src_warped:         #IMG_WARPED_PATH01
							_combined:           #IMG_WARPED_PATH0
							_src_field:          #COMBINED_FIELDS_PATH01
							_errors:             #ERRORS_PATH0001
						},
						#COMBINED_FLOW_TMPL & {
							_bbox_:              _bbox
							_encoded_src:        #ENCODED_PATH11
							_encoded_tgt:        #ENCODED_PATH10
							_encoded_src_warped: #ENCODED_WARPED_PATH11
							_encoded_combined:   #ENCODED_WARPED_PATH1
							_src:                #IMG_PATH11
							_tgt:                #IMG_PATH10
							_src_warped:         #IMG_WARPED_PATH11
							_combined:           #IMG_WARPED_PATH1
							_src_field:          #COMBINED_FIELDS_PATH11
							_errors:             #ERRORS_PATH1011
						},
					]
				},
				#COMBINED_FLOW_TMPL & {
					_bbox_:              _bbox
					_encoded_src:        #ENCODED_WARPED_PATH1
					_encoded_tgt:        #ENCODED_WARPED_PATH0
					_encoded_src_warped: #ENCODED_WARPED_PATH1_WARPED
					_encoded_combined:   #ENCODED_WARPED_PATH_FINAL
					_src:                #IMG_WARPED_PATH1
					_tgt:                #IMG_WARPED_PATH0
					_src_warped:         #IMG_WARPED_PATH1_WARPED
					_combined:           #IMG_WARPED_PATH_FINAL
					_src_field:          #COMBINED_FIELDS_PATH1
					_errors:             #ERRORS_PATH01
				},
				for res in #DOWNSAMPLE_ERROR_FINAL_RESES {
					#DOWNSAMPLE_FLOW_TMPL & {
						bbox: _bbox
						op: mode: "img"
						op_kwargs: src: path: #ERRORS_PATH_FINAL
						dst: path: #ERRORS_PATH_FINAL
						dst_resolution: [res, res, 50]
					}
				},
				// Downsample Combined Images
				for res in #DOWNSAMPLE_ERROR_FINAL_RESES {
					#DOWNSAMPLE_FLOW_TMPL & {
						bbox: _bbox
						op: mode: "img"
						op_kwargs: src: path: #IMG_WARPED_PATH_FINAL
						dst: path: #IMG_WARPED_PATH_FINAL
						dst_resolution: [res, res, 50]
					}
				},
			]
		},
	]
}

#COMBINED_FLOW_TMPL: {
	"@type":             "mazepa.sequential_flow"
	_bbox_:              _
	_src:                _
	_tgt:                _
	_src_warped:         _
	_encoded_src:        _
	_encoded_tgt:        _
	_encoded_src_warped: _
	_src_field:          _
	_encoded_combined:   _
	_combined:           _
	_errors:             _
	stages: [
		{"@type": "mazepa.concurrent_flow"
			stages: [
				{"@type": "mazepa.sequential_flow"
					stages: [
						// Warp Images
						#WARP_FLOW_TMPL & {
							bbox: _bbox_
							op: mode:                 "img"
							dst: path:                _src_warped
							dst: info_reference_path: _src
							dst_resolution: #IMG_WARP_RES
							op_kwargs: src: path: _src
							op_kwargs: src: index_procs: [
								{
									"@type": "VolumetricIndexTranslator"
									offset: [0, 0, 0]
									resolution: #IMG_RES
								},
							]
							op_kwargs: field: path:            _src_field
							op_kwargs: field: data_resolution: #STAGES[len(#STAGES)-1].dst_resolution
						},
						{"@type": "mazepa.concurrent_flow"
							stages: [
								{"@type": "mazepa.sequential_flow"
									stages: [
										// Downsample Warped Images - only needed for Errors
										for res in #DOWNSAMPLE_ERROR_RESES {
											#DOWNSAMPLE_FLOW_TMPL & {
												bbox: _bbox_
												op: mode: "img"
												op_kwargs: src: path: _src_warped
												dst: path: _src_warped
												dst_resolution: [res, res, 50]
											}
										},
									]
								},
								{"@type": "mazepa.sequential_flow"
									stages: [
										// Combine Warped Images
										#COMBINE_IMAGE_FLOW_TMPL & {
											bbox: _bbox_
											dst: path:                _combined
											dst: info_reference_path: _tgt
											dst_resolution: #IMG_WARP_RES
											op_kwargs: data1: path: _tgt
											op_kwargs: data2: path: _src_warped
										},
										// Downsample Combined Images - only needed for Errors
										for res in #DOWNSAMPLE_ERROR_RESES {
											#DOWNSAMPLE_FLOW_TMPL & {
												bbox: _bbox_
												op: mode: "img"
												op_kwargs: src: path: _combined
												dst: path: _combined
												dst_resolution: [res, res, 50]
											}
										},
									]
								},
							]
						},
					]
				},
			]
		},
	]
}

#CF_FLOW_TMPL: {
	"@type":           "build_compute_field_multistage_flow"
	bbox:              _
	stages:            #STAGES
	src_offset?:       _
	tgt_offset?:       _
	src_field?:        _
	offset_resolution: #IMG_RES
	src: {
		"@type": "build_cv_layer"
		path:    _
	}
	tgt: {
		"@type": "build_cv_layer"
		path:    _
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: #IMG_PATH00
		info_field_overrides: {
			"type":         "image"
			"data_type":    "float32"
			"num_channels": 2
		}
		on_info_exists: "overwrite"
	}
	tmp_layer_dir: _
	tmp_layer_factory: {
		"@type":             "build_cv_layer"
		"@mode":             "partial"
		info_reference_path: dst.path
		on_info_exists:      "overwrite"
	}
}

#STAGES: [
	// #CF_FINETUNER_STAGE_TMPL & {
	//  fn: sm:       500
	//  fn: num_iter: #NUM_ITER
	//  dst_resolution: [320, 320, #IMG_RES[2]]
	// },
	// #CF_BM_PWA_STAGE_TMPL & {
	//  dst_resolution: [80, 80, #IMG_RES[2]]
	// },
	//  #CF_FINETUNER_STAGE_TMPL & {
	//   fn: sm:       500
	//   fn: num_iter: #NUM_ITER
	//   dst_resolution: [320, 320, #IMG_RES[2]]
	//  },
	// 2 param
	// #CF_BM_PWA_STAGE_TMPL & {
	//  dst_resolution: [320, 320, #IMG_RES[2]]
	//  tile_size:      int | *31
	//  tile_step:      int | *12
	//  min_overlap_px: int | *160
	//  max_disp:       int | *2
	//  r_delta:        int | *1.5
	// },
	// #CF_FINETUNER_STAGE_TMPL & {
	//  fn: sm:       500
	//  fn: num_iter: #NUM_ITER
	//  dst_resolution: [320, 320, #IMG_RES[2]]
	// },
	// #CF_BM_PWA_STAGE_TMPL & {
	//  dst_resolution: [640, 640, #IMG_RES[2]]
	// },
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       1000
		fn: num_iter: #NUM_ITER
		dst_resolution: [640, 640, #IMG_RES[2]]
	},
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       500
		fn: num_iter: #NUM_ITER
		dst_resolution: [320, 320, #IMG_RES[2]]
	},
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       250
		fn: num_iter: #NUM_ITER
		dst_resolution: [160, 160, #IMG_RES[2]]
	},
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       50
		fn: num_iter: #NUM_ITER
		dst_resolution: [80, 80, #IMG_RES[2]]
	},
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       25
		fn: num_iter: #NUM_ITER
		dst_resolution: [40, 40, #IMG_RES[2]]
	},
	#CF_FINETUNER_STAGE_TMPL & {
		fn: sm:       10
		fn: num_iter: #NUM_ITER
		dst_resolution: [20, 20, #IMG_RES[2]]
	},
]
#CF_BM_PWA_STAGE_TMPL: {
	"@type":        "ComputeFieldStage"
	dst_resolution: _
	// processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_chunk_sizes: [[1024 * 2, 1024 * 2, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	processing_blend_pads: [[0, 0, 0], [0, 0, 0]]
	// skip_intermediaries:     true
	//                       level_intermediaries_dirs: [#TMP_PATH, #TMP_PATH_LOCAL]
	expand_bbox_processing:  bool | *true
	shrink_processing_chunk: bool | *false
	fn: {
		"@type":        "align_with_blockmatch_based_piecewise_affine"
		"@mode":        "partial"
		tile_size:      int | *15
		tile_step:      int | *5
		min_overlap_px: int | *220
		max_disp:       int | *3
		r_delta:        int | *1.4
	}
}

#CF_FINETUNER_STAGE_TMPL: {
	"@type":        "ComputeFieldStage"
	dst_resolution: _
	// processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_chunk_sizes: [[1024 * 2, 1024 * 2, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [64, 64, 0]]
	processing_blend_pads: [[0, 0, 0], [0, 0, 0]]
	// skip_intermediaries:     true
	//                       level_intermediaries_dirs: [#TMP_PATH, #TMP_PATH_LOCAL]
	expand_bbox_processing:  bool | *true
	shrink_processing_chunk: bool | *false
	fn: {
		"@type":        "align_with_online_finetuner"
		"@mode":        "partial"
		sm:             _
		num_iter:       _
		lr?:            float | *0.1
		bake_in_field?: bool
	}
}

#WARP_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	op: {
		"@type": "WarpOperation"
		mode:    _
	}
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	skip_intermediaries: true
	bbox:                _
	dst_resolution:      _
	op_kwargs: {
		src: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		field: {
			"@type":            "build_cv_layer"
			path:               _
			data_resolution:    _ | *null
			interpolation_mode: "field"
		}
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: _
		// info_add_scales_ref: "4_4_160"
		//  info_add_scales: [dst_resolution]
		//  info_add_scales_mode: "replace"
		info_chunk_size: [512, 512, 1]
		on_info_exists: "overwrite"
		write_procs?:   _
		index_procs?:   _ | *[]
	}
}
#COMBINE_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type":    "lambda"
		lambda_str: "lambda data1, data2: torch.where(torch.abs(data1) > torch.abs(data2), data1, data2)"
	}
	fn_semaphores: ["cpu"]
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	skip_intermediaries: true
	bbox:                _
	dst_resolution:      _
	op_kwargs: {
		data1: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		data2: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: _
		// info_add_scales_ref: "4_4_160"
		//  info_add_scales: [dst_resolution]
		//  info_add_scales_mode: "replace"
		info_chunk_size: [512, 512, 1]
		on_info_exists: "overwrite"
		write_procs?:   _
		index_procs?:   _ | *[]
	}
}
#COMBINE_IMAGE_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type": "erode_combine"
		"@mode": "partial"
	}
	fn_semaphores: ["cpu"]
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	skip_intermediaries: true
	bbox:                _
	dst_resolution:      _
	op_kwargs: {
		data1: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		data2: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		erosion: 5
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: _
		// info_add_scales_ref: "4_4_160"
		//  info_add_scales: [dst_resolution]
		//  info_add_scales_mode: "replace"
		info_chunk_size: [512, 512, 1]
		on_info_exists: "overwrite"
		write_procs?:   _
		index_procs?:   _ | *[]
	}
}
#COMBINE_THREE_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type":    "lambda"
		lambda_str: "lambda data1, data2, data3: torch.maximum(data1, torch.maximum(data2, data3))"
	}
	fn_semaphores: ["cpu"]
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	skip_intermediaries: true
	bbox:                _
	dst_resolution:      _ | *#ERROR_RES
	op_kwargs: {
		data1: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		data2: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		data3: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: _
		info_chunk_size: [512, 512, 1]
		on_info_exists: "overwrite"
		write_procs?:   _
		index_procs?:   _ | *[]
	}
}
#ERROR_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	fn: {
		"@type": "compute_pixel_error"
		"@mode": "partial"
	}
	fn_semaphores: ["cpu"]
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [256, 256, 0]]
	skip_intermediaries: true
	bbox:                _
	dst_resolution:      _
	op_kwargs: {
		data1: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
		data2: {
			"@type":      "build_cv_layer"
			path:         _
			read_procs?:  _
			index_procs?: _ | *[]
		}
	}
	dst: {
		"@type":             "build_cv_layer"
		path:                _
		info_reference_path: _
		// info_add_scales_ref: "4_4_160"
		//  info_add_scales: [dst_resolution]
		//  info_add_scales_mode: "replace"
		info_chunk_size: [512, 512, 1]
		on_info_exists: "overwrite"
		write_procs?:   _
		index_procs?:   _ | *[]
	}
}

#DOWNSAMPLE_FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	//expand_bbox_processing: true
	shrink_processing_chunk: false
	skip_intermediaries:     true
	processing_chunk_sizes: [[1024 * 4, 1024 * 4, 1], [1024 * 2, 1024 * 2, 1]]
	processing_crop_pads: [[0, 0, 0], [0, 0, 0]]
	op: {
		"@type":         "InterpolateOperation"
		mode:            _ | "img"
		res_change_mult: _ | *[2, 2, 1]
	}
	bbox: _
	op_kwargs: {
		src: {
			"@type":    "build_cv_layer"
			path:       _
			read_procs: _ | *[]
		}
	}
	dst: {
		"@type": "build_cv_layer"
		path:    _
	}
	dst_resolution: _
}
