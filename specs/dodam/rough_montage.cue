"@type":                "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region:  "us-east1"
worker_image:           "us.gcr.io/dacey-human-retina-001/zetta_utils:dodam-rough-montage-3"
worker_cluster_project: "dacey-human-retina-001"
worker_cluster_name:    "zutils"
// worker_image:           "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-8"
// worker_cluster_project: "zetta-research"
// worker_cluster_name:    "zutils-x3"
worker_replicas: 1500
local_test:      false
target: {
	"@type":      "rough_montage"
	path:         "~/importlist.total.csv"
	bucket:       "gs://dacey-human-retina-001-drop/tiffs.unfiltered.uncropped"
	exp_offset:   7024
	crop:         64
	ds_factor:    8
	max_disp:     64
	//z_start:      0
	//z_stop:       5000
	z_start: 0
	z_stop:  3080
}
num_procs: 2
semaphores_spec: {
	"read":  2
	"cpu":   2
	"cuda":  1
	"write": 2
}
do_dryrun_estimation: false
