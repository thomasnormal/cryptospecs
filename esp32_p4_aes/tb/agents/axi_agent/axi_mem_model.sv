// AXI Memory Model
// Byte-addressable memory using an associative array.
// Provides word-level read/write methods, bulk preload, and dump utility.

class axi_mem_model extends uvm_object;

    `uvm_object_utils(axi_mem_model)

    // ---------------------------------------------------------------
    // Associative array: byte-addressable storage
    // ---------------------------------------------------------------
    bit [7:0] mem [bit [31:0]];

    // ---------------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------------
    function new(string name = "axi_mem_model");
        super.new(name);
    endfunction : new

    // ---------------------------------------------------------------
    // write_byte - Write a single byte
    // ---------------------------------------------------------------
    function void write_byte(bit [31:0] addr, bit [7:0] data);
        mem[addr] = data;
    endfunction : write_byte

    // ---------------------------------------------------------------
    // read_byte - Read a single byte (returns 0 if uninitialized)
    // ---------------------------------------------------------------
    function bit [7:0] read_byte(bit [31:0] addr);
        if (mem.exists(addr))
            return mem[addr];
        else
            return 8'h00;
    endfunction : read_byte

    // ---------------------------------------------------------------
    // write_word - Write a 32-bit word (little-endian byte order)
    // ---------------------------------------------------------------
    function void write_word(bit [31:0] addr, bit [31:0] data);
        bit [31:0] aligned_addr = {addr[31:2], 2'b00};
        mem[aligned_addr + 0] = data[7:0];
        mem[aligned_addr + 1] = data[15:8];
        mem[aligned_addr + 2] = data[23:16];
        mem[aligned_addr + 3] = data[31:24];
    endfunction : write_word

    // ---------------------------------------------------------------
    // write_word_strobed - Write a 32-bit word with byte strobes
    // ---------------------------------------------------------------
    function void write_word_strobed(bit [31:0] addr, bit [31:0] data, bit [3:0] wstrb);
        bit [31:0] aligned_addr = {addr[31:2], 2'b00};
        if (wstrb[0]) mem[aligned_addr + 0] = data[7:0];
        if (wstrb[1]) mem[aligned_addr + 1] = data[15:8];
        if (wstrb[2]) mem[aligned_addr + 2] = data[23:16];
        if (wstrb[3]) mem[aligned_addr + 3] = data[31:24];
    endfunction : write_word_strobed

    // ---------------------------------------------------------------
    // read_word - Read a 32-bit word (little-endian byte order)
    // ---------------------------------------------------------------
    function bit [31:0] read_word(bit [31:0] addr);
        bit [31:0] aligned_addr = {addr[31:2], 2'b00};
        bit [31:0] data;
        data[7:0]   = read_byte(aligned_addr + 0);
        data[15:8]  = read_byte(aligned_addr + 1);
        data[23:16] = read_byte(aligned_addr + 2);
        data[31:24] = read_byte(aligned_addr + 3);
        return data;
    endfunction : read_word

    // ---------------------------------------------------------------
    // preload - Load an array of 32-bit words starting at addr
    // ---------------------------------------------------------------
    function void preload(bit [31:0] addr, bit [31:0] data[]);
        foreach (data[i]) begin
            write_word(addr + (i * 4), data[i]);
        end
    endfunction : preload

    // ---------------------------------------------------------------
    // dump - Print memory contents for debug
    // ---------------------------------------------------------------
    function void dump(string tag = "AXI_MEM");
        bit [31:0] addr_list[$];
        bit [31:0] a;

        // Collect all addresses (word-aligned, unique)
        if (mem.first(a)) begin
            do begin
                bit [31:0] wa = {a[31:2], 2'b00};
                if (addr_list.size() == 0 || addr_list[$] != wa)
                    addr_list.push_back(wa);
            end while (mem.next(a));
        end

        `uvm_info(tag, $sformatf("Memory dump (%0d words):", addr_list.size()), UVM_LOW)
        foreach (addr_list[i]) begin
            `uvm_info(tag, $sformatf("  [0x%08h] = 0x%08h",
                addr_list[i], read_word(addr_list[i])), UVM_LOW)
        end
    endfunction : dump

    // ---------------------------------------------------------------
    // clear - Erase all memory contents
    // ---------------------------------------------------------------
    function void clear();
        mem.delete();
    endfunction : clear

    // ---------------------------------------------------------------
    // size - Return number of bytes stored
    // ---------------------------------------------------------------
    function int size();
        return mem.size();
    endfunction : size

endclass : axi_mem_model
