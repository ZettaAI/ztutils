//#BASE_FOLDER: "gs://dacey-human-retina-001-montaging/test_tiles_8192full_64crop_6912offset"

#BASE_FOLDER: "gs://hive-tomography/pilot11-tiles/rough_montaged_nocrop_23"

#BBOX: {
	"@type": "BBox3D.from_coords"
	start_coord: [0, 0, 0]
	end_coord: [786432, 262144, 1]
	resolution: [1, 1, 1]

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
		//res_change_mult: _ | *[8, 8, 1]
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

"@type":               "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region: "us-east1"
worker_image:          "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-hive-12"
worker_resources: {
	memory: "18560Mi" // sized for n1-highmem-4
}
worker_cluster_project: "zetta-research"
worker_cluster_name:    "zutils-x3"
worker_replicas:        500
local_test:             false
debug:                  false
num_procs:              2
target: {
	"@type": "mazepa.concurrent_flow"
	stages: [
		for offset in ["(0,0)", "(0,1)", "(1,0)", "(1,1)"] {
			"@type": "mazepa.sequential_flow"
			stages: [
				for res in [2, 4, 8, 16, 32, 64, 128, 256, 512] {
					//   for res in [8, 64, 512] {
					#FLOW_TMPL & {
						processing_chunk_sizes: [[1024 * 6, 1024 * 4, 4], [1024 * 2, 1024 * 2, 1]]

						op: mode: "img"
						op_kwargs: src: path: "\(#BASE_FOLDER)/\(offset)"
						dst: path: "\(#BASE_FOLDER)/\(offset)"
						dst_resolution: [res, res, 1]
					}
				},
			]
		},
	]
}
debug: false
