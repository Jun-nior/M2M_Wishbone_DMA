+incdir+out/
+incdir+rggen-sv-rtl/
+incdir+RTL/

-f ./rggen-sv-rtl/compile.f

./out/DMA_CSR.sv

./RTL/bram.sv
./RTL/wishbone_bram_wrapper.sv
./RTL/wishbone_master_agent.sv
./RTL/wishbone_interconnect.sv
./RTL/dma_fsm.sv
./RTL/dma_controller.sv
./RTL/dma_system.sv

./TB/DMA_CSR_tb_top.sv
./TB/wishbone_master_agent_tb_top.sv
./TB/dma_fsm_tb_top.sv
./TB/dma_system_tb_top.sv