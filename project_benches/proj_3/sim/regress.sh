make     cli GEN_TRANS_TYPE=i2cmb_test
make run_cli GEN_TRANS_TYPE=test_i2cmb_consecutive_starts TEST_SEED=543210
make run_cli GEN_TRANS_TYPE=test_i2cmb_consecutive_stops TEST_SEED=random
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_addr TEST_SEED=random
make run_cli GEN_TRANS_TYPE=test_i2cmb_reg_vals TEST_SEED=random
make run_cli GEN_TRANS_TYPE=test_i2cmb_rw_ability TEST_SEED=random
make run_cli GEN_TRANS_TYPE=test_i2cmb_writes TEST_SEED=random
make merge_coverage
