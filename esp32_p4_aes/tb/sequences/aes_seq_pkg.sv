// AES Sequence Package

package aes_seq_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import ahb_agent_pkg::*;
    import axi_agent_pkg::*;
    import aes_ral_pkg::*;
    import aes_env_pkg::*;

    `include "aes_base_seq.sv"
    `include "aes_typical_ecb_seq.sv"
    `include "aes_consecutive_ecb_seq.sv"
    `include "aes_reg_smoke_seq.sv"
    `include "aes_dma_ecb_seq.sv"
    `include "aes_dma_cbc_seq.sv"
    `include "aes_dma_ofb_seq.sv"
    `include "aes_dma_ctr_seq.sv"
    `include "aes_dma_cfb_seq.sv"
    `include "aes_dma_gcm_seq.sv"

endpackage
