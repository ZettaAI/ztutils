"@type":                "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region:  "us-east1"
worker_image:           "us.gcr.io/dacey-human-retina-001/zetta_utils:dodam-rough-montage-3"
worker_cluster_project: "dacey-human-retina-001"
worker_cluster_name:    "zutils"
// worker_image:           "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-8"
// worker_cluster_project: "zetta-research"
// worker_cluster_name:    "zutils-x3"
//worker_resources: {
// memory:           "18560Mi" // sized for n1-highmem-4
// "nvidia.com/gpu": "1"
//}
worker_replicas: 800
local_test:      false
target: {
	"@type":            "write_files_from_csv"
	csv_path:           "./elastic_rough_montage_64crop_8x64_uniform.csv"
	bucket:             "gs://dacey-human-retina-001-drop/tiffs.unfiltered.uncropped"
	info_template_path: "gs://zetta-research-dodam/dacey-montaging-research/prototype/"
	base_path:          "gs://dacey-human-retina-001-montaging/elastic_rough_aligned_384importcrop_64crop_8x64_uniform_final"
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
	crop:               394
	// base_path: "gs://dacey-human-retina-001-montaging/rough_aligned_elastic_linear"
	resolution: [5, 5, 50]
}
num_procs: 1
semaphores_spec: {
	"read":  2
	"cpu":   2
	"cuda":  1
	"write": 2
}
do_dryrun_estimation: false
