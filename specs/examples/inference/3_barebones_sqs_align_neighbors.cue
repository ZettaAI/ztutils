#SRC_PATH: "https://storage.googleapis.com/fafb_v15_aligned/v0/img/img"
#DST_PATH: "gs://tmp_2w/fafb_copy_x0/img"
#BCUBE: {
	"@type": "BoundingCube"
	start_coord: [0, 0, 2000]
	end_coord: [1024, 1024, 20010]
	resolution: [512, 512, 40]
}

"@type": "invoke"
obj: {
	"@type": "ChunkedProcessor"
	inner_processor: {
		"@type": ""
	}
	chunker: {
		"@type": "VolumetricIndexChunker"
		chunk_size: [1024, 1024, 1]
		step_size: [1024, 1024, 1]
	}
	executor: {
		"@type": "MazepaExecutor"
		exec_queue: {
			"@type":            "MazepaSQSExecutionQueue"
			name:               "sergiy-corgie-x0"
			outcome_queue_name: "sergiy-corgie-completion-x0"
		}
		purge_at_start: false
	}
}
params: {
	layers: {
		src: {
			"@type": "build_cv_layer"
			path:    #SRC_PATH
		}
		dst: {
			"@type":             "build_cv_layer"
			path:                #DST_PATH
			info_reference_path: #SRC_PATH
			on_info_exists:      "expect_same"
		}
	}
	idx: {
		"@type": "VolumetricIndex"
		bcube:   #BCUBE
		resolution: [64, 64, 40]
	}
}
