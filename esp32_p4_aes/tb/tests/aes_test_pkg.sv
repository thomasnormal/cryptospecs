// AES Test Package

package aes_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ahb_agent_pkg::*;
    import axi_agent_pkg::*;
    import aes_ral_pkg::*;
    import aes_env_pkg::*;
    import aes_seq_pkg::*;

    `include "aes_base_test.sv"
    `include "aes_typical_128_ecb_test.sv"
    `include "aes_typical_256_ecb_test.sv"
    `include "aes_reg_smoke_test.sv"
    `include "aes_typical_consecutive_test.sv"
    `include "aes_dma_128_ecb_test.sv"
    `include "aes_dma_256_ecb_test.sv"
    `include "aes_dma_cbc_test.sv"
    `include "aes_dma_ofb_test.sv"
    `include "aes_dma_ctr_test.sv"
    `include "aes_dma_cfb_test.sv"
    `include "aes_dma_gcm_test.sv"
    `include "aes_dma_256_cbc_test.sv"
    `include "aes_dma_256_ofb_test.sv"
    `include "aes_dma_256_ctr_test.sv"

endpackage
