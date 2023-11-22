		//#BASE_FOLDER: "gs://dacey-human-retina-001-montaging/test_tiles_8192full_64crop_6912offset"

#BASE_FOLDER: "gs://dacey-human-retina-001-montaging/elastic_rough_aligned_384importcrop_64crop_8x64_uniform_final"


#BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, 1]
	end_coord: [40960, 40960, 3030]
	resolution: [5, 5, 50]

}

#FLOW_TMPL: {
	"@type": "build_subchunkable_apply_flow"
	//expand_bbox_processing: true
	shrink_processing_chunk: false
	skip_intermediaries:     true
	processing_chunk_sizes:  _
	dst_resolution:          _
	op: {
		"@type":         "InterpolateOperation"
		mode:            _
		res_change_mult: _ | *[2, 2, 1]
	}
	bbox: #BBOX
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

}

"@type":                "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region:  "us-east1"
worker_image:           "us.gcr.io/dacey-human-retina-001/zetta_utils:dodam-rough-montage-3"
worker_cluster_project: "dacey-human-retina-001"
worker_cluster_name:    "zutils"
worker_resources: {
	memory: "18560Mi" // sized for n1-highmem-4
}
worker_replicas: 500
num_procs:       2
target: {
	"@type": "mazepa.concurrent_flow"
	stages: [
		for offset in ["(0,0)", "(0,1)", "(1,0)", "(1,1)"] {
			"@type": "mazepa.sequential_flow"
			stages: [
				for res in [10, 20, 40, 80, 160, 320, 640, 1280] {
					#FLOW_TMPL & {
						processing_chunk_sizes: [[1024 * 8, 1024 * 8, 4], [1024 * 4, 1024 * 4, 1]]

						op: mode: "img"
						op_kwargs: src: path: "\(#BASE_FOLDER)/\(offset)"
						dst: path: "\(#BASE_FOLDER)/\(offset)"
						dst_resolution: [res, res, 50]
					}
				},
			]
		},
	]
}
debug: false
