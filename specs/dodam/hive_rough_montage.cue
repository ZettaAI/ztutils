"@type":                "mazepa.execute_on_gcp_with_sqs"
worker_cluster_region:  "us-east1"
worker_image:           "us.gcr.io/zetta-research/zetta_utils:dodam-montage-blockmatch-hive-23"
worker_cluster_project: "zetta-research"
worker_cluster_name:    "zutils-x3"
worker_replicas:        2000
local_test:             false
debug:                  false
//local_test: true
//debug:      true
target: {
	"@type":          "compute_rough_montage_offsets"
	path:             "~/stage_positions.csv"
	bucket:           "gs://ng_scratch_ranl_7/test_voxa/tiles/2022.10.01_Sample3_tilt-0/s000.01-2022.10.02-20.37.54/"
	exp_offset:       4672
	crop:             0
	patch_size_limit: 512
	ds_factor:        1
	max_disp:         420
	//ds_factor: 2
	//max_disp:  256
	// ds_factor: 8
	// max_disp:  64
	//         max_disp_lobster: 256
	//         max_disp_crab:    64
	//z_start:      0
	//z_stop:       5000
	z_start: 0
	z_stop:  3080
	encoder: {
		"@type":     "BaseCoarsener"
		model_path:  "gs://zetta-research-nico/training_artifacts/general_encoder_loss/4.0.1_M3_M3_C1_lr0.0002_locality1.0_similarity0.0_l10.0-0.03_N1x4/last.ckpt.model.spec.json"
		tile_pad_in: #ENCODE_CROP_PAD[0]
		tile_size:   5496 / 8
		ds_factor:   1
	}
}
#ENCODE_CROP_PAD: [16, 16, 0] // 16 pix was okay for 1um model
num_procs:                    2
semaphores_spec: {
	"read":  2
	"cpu":   2
	"cuda":  1
	"write": 2
}
worker_resources: {
	memory: "18560Mi" // sized for n1-highmem-4

	// "nvidia.com/gpu": "1"
}
do_dryrun_estimation: false
