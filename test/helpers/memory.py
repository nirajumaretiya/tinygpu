from typing import List
from .logger import logger

class Memory:
    def __init__(self, dut, addr_bits, data_bits, channels, name):
        self.dut = dut
        self.addr_bits = addr_bits
        self.data_bits = data_bits
        self.memory = [0] * (2**addr_bits)
        self.channels = channels
        self.name = name

        self.mem_read_valid = getattr(dut, f"{name}_mem_read_valid")
        self.mem_read_address = getattr(dut, f"{name}_mem_read_address")
        self.mem_read_ready = getattr(dut, f"{name}_mem_read_ready")
        self.mem_read_data = getattr(dut, f"{name}_mem_read_data")

        if name != "program":
            self.mem_write_valid = getattr(dut, f"{name}_mem_write_valid")
            self.mem_write_address = getattr(dut, f"{name}_mem_write_address")
            self.mem_write_data = getattr(dut, f"{name}_mem_write_data")
            self.mem_write_ready = getattr(dut, f"{name}_mem_write_ready")

    def run(self):
        # Interpret packed buses LSB-first to match Verilog [i*BITS +: BITS]
        rv_int = int(self.mem_read_valid.value)
        ra_int = int(self.mem_read_address.value)

        mem_read_valid = [(rv_int >> ch) & 0x1 for ch in range(self.channels)]
        mem_read_address = [
            (ra_int >> (ch * self.addr_bits)) & ((1 << self.addr_bits) - 1)
            for ch in range(self.channels)
        ]
        mem_read_ready = [0] * self.channels
        mem_read_data = [0] * self.channels

        for i in range(self.channels):
            if mem_read_valid[i] == 1:
                mem_read_data[i] = self.memory[mem_read_address[i]]
                mem_read_ready[i] = 1
            else:
                mem_read_ready[i] = 0

        # Pack back LSB-first
        rd_val = 0
        for ch in range(self.channels):
            rd_val |= (mem_read_data[ch] & ((1 << self.data_bits) - 1)) << (ch * self.data_bits)
        rr_val = 0
        for ch in range(self.channels):
            rr_val |= (mem_read_ready[ch] & 0x1) << ch
        self.mem_read_data.value = rd_val
        self.mem_read_ready.value = rr_val

        if self.name != "program":
            wv_int = int(self.mem_write_valid.value)
            wa_int = int(self.mem_write_address.value)
            wd_int = int(self.mem_write_data.value)

            mem_write_valid = [(wv_int >> ch) & 0x1 for ch in range(self.channels)]
            mem_write_address = [
                (wa_int >> (ch * self.addr_bits)) & ((1 << self.addr_bits) - 1)
                for ch in range(self.channels)
            ]
            mem_write_data = [
                (wd_int >> (ch * self.data_bits)) & ((1 << self.data_bits) - 1)
                for ch in range(self.channels)
            ]
            mem_write_ready = [0] * self.channels

            for i in range(self.channels):
                if mem_write_valid[i] == 1:
                    self.memory[mem_write_address[i]] = mem_write_data[i]
                    mem_write_ready[i] = 1
                else:
                    mem_write_ready[i] = 0

            wr_val = 0
            for ch in range(self.channels):
                wr_val |= (mem_write_ready[ch] & 0x1) << ch
            self.mem_write_ready.value = wr_val

    def write(self, address, data):
        if address < len(self.memory):
            self.memory[address] = data

    def load(self, rows: List[int]):
        for address, data in enumerate(rows):
            self.write(address, data)

    def display(self, rows, decimal=True):
        logger.info("\n")
        logger.info(f"{self.name.upper()} MEMORY")
        
        table_size = (8 * 2) + 3
        logger.info("+" + "-" * (table_size - 3) + "+")

        header = "| Addr | Data "
        logger.info(header + " " * (table_size - len(header) - 1) + "|")

        logger.info("+" + "-" * (table_size - 3) + "+")
        for i, data in enumerate(self.memory):
            if i < rows:
                if decimal:
                    row = f"| {i:<4} | {data:<4}"
                    logger.info(row + " " * (table_size - len(row) - 1) + "|")
                else:
                    data_bin = format(data, f'0{16}b')
                    row = f"| {i:<4} | {data_bin} |"
                    logger.info(row + " " * (table_size - len(row) - 1) + "|")
        logger.info("+" + "-" * (table_size - 3) + "+")