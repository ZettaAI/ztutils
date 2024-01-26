"@type":                "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region:  "us-east1"
worker_image:           "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-hive-12"
worker_cluster_project: "zetta-research"
worker_cluster_name:    "zutils-x3"
worker_replicas:        250
local_test:             false
debug:                  false
target: {
	"@type":            "write_files_from_csv"
	tile_locs_path:     "./tiles.json"
	csv_path:           "./rough_montage.csv"
	bucket:             "gs://ng_scratch_ranl_7/test_voxa/tiles/2022.10.01_Sample3_tilt-0/s000.01-2022.10.02-20.37.54/"
	info_template_path: "gs://hive-tomography/pilot11-tiles"
	base_path:          "gs://hive-tomography/pilot11-tiles/rough_montaged_nocrop_14"
	//    "@type": "mazepa.sequential_flow"
	//    stages: [
	//     for res in [40, 80, 160, 320] {
	//      #DOWNSAMPLE_FLOW_TMPL & {
	//       bbox: _bbox
	//       op: mode:  "img"
	//       op_kwargs: src: path: #IMG_WARPED_PATH0
	//       dst: path: #IMG_WARPED_PATH0
	//       dst_resolution: [res, res, 50]
	//      },
	//     },
	//    ]
	crop: 0
	// base_path: "gs://dacey-human-retina-001-montaging/rough_aligned_elastic_linear"
	resolution: [1, 1, 1]
}
num_procs: 1
semaphores_spec: {
	"read":  2
	"cpu":   2
	"cuda":  1
	"write": 2
}
do_dryrun_estimation: false
