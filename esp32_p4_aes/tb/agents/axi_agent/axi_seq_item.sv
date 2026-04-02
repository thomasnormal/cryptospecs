// AXI4 Sequence Item
// Represents a complete AXI4 read or write transaction.
// Contains address, data (dynamic array for burst support),
// burst parameters, and response.

class axi_seq_item extends uvm_sequence_item;

    // ---------------------------------------------------------------
    // Direction Enum
    // ---------------------------------------------------------------
    typedef enum bit {
        AXI_READ  = 1'b0,
        AXI_WRITE = 1'b1
    } axi_rw_e;

    // ---------------------------------------------------------------
    // AXI Response Enum
    // ---------------------------------------------------------------
    typedef enum logic [1:0] {
        AXI_OKAY   = 2'b00,
        AXI_EXOKAY = 2'b01,
        AXI_SLVERR = 2'b10,
        AXI_DECERR = 2'b11
    } axi_resp_e;

    // ---------------------------------------------------------------
    // Fields
    // ---------------------------------------------------------------
    rand bit [31:0]  addr;
    rand bit [31:0]  data[];       // Dynamic array - one entry per beat
    rand bit [7:0]   burst_len;    // AXI AxLEN (actual beats = burst_len + 1)
    rand bit [2:0]   burst_size;   // AXI AxSIZE (bytes per beat = 2^burst_size)
    rand bit [1:0]   burst_type;   // AXI AxBURST: 00=FIXED, 01=INCR, 10=WRAP
    rand axi_rw_e    rw;
         axi_resp_e  resp;

    // Transaction metadata
    bit [3:0]        id;           // AXI AxID
    bit [3:0]        wstrb[];      // Write strobes per beat

    // ---------------------------------------------------------------
    // UVM Macros
    // ---------------------------------------------------------------
    `uvm_object_utils_begin(axi_seq_item)
        `uvm_field_int       (addr,       UVM_ALL_ON)
        `uvm_field_array_int (data,       UVM_ALL_ON)
        `uvm_field_int       (burst_len,  UVM_ALL_ON)
        `uvm_field_int       (burst_size, UVM_ALL_ON)
        `uvm_field_int       (burst_type, UVM_ALL_ON)
        `uvm_field_enum      (axi_rw_e,   rw,   UVM_ALL_ON)
        `uvm_field_enum      (axi_resp_e,  resp, UVM_ALL_ON)
        `uvm_field_int       (id,         UVM_ALL_ON)
        `uvm_field_array_int (wstrb,      UVM_ALL_ON)
    `uvm_object_utils_end

    // ---------------------------------------------------------------
    // Constraints
    // ---------------------------------------------------------------
    constraint c_data_size {
        data.size() == burst_len + 1;
    }

    constraint c_wstrb_size {
        wstrb.size() == burst_len + 1;
    }

    constraint c_burst_size_valid {
        burst_size <= 3'b010;  // Max 4 bytes for 32-bit data bus
    }

    constraint c_burst_type_valid {
        burst_type inside {2'b00, 2'b01, 2'b10};
    }

    constraint c_addr_aligned {
        addr[1:0] == 2'b00;  // Word-aligned for 32-bit bus
    }

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    function new(string name = "axi_seq_item");
        super.new(name);
        resp = AXI_OKAY;
    endfunction : new

    // ---------------------------------------------------------------
    // convert2string
    // ---------------------------------------------------------------
    virtual function string convert2string();
        string s;
        s = $sformatf("\n---------- AXI Transaction ----------");
        s = {s, $sformatf("\n  Direction  : %s",   rw.name())};
        s = {s, $sformatf("\n  ID         : 0x%0h", id)};
        s = {s, $sformatf("\n  Address    : 0x%08h", addr)};
        s = {s, $sformatf("\n  Burst Len  : %0d (beats = %0d)", burst_len, burst_len + 1)};
        s = {s, $sformatf("\n  Burst Size : %0d (%0d bytes/beat)", burst_size, 2**burst_size)};
        s = {s, $sformatf("\n  Burst Type : %0d (%s)", burst_type,
            (burst_type == 2'b00) ? "FIXED" :
            (burst_type == 2'b01) ? "INCR"  :
            (burst_type == 2'b10) ? "WRAP"  : "RSVD")};
        s = {s, $sformatf("\n  Response   : %s", resp.name())};
        for (int i = 0; i < data.size(); i++) begin
            s = {s, $sformatf("\n  Data[%0d]   : 0x%08h", i, data[i])};
        end
        s = {s, "\n--------------------------------------\n"};
        return s;
    endfunction : convert2string

endclass : axi_seq_item
