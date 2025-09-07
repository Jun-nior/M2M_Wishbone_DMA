## DMA_CSR

* byte_size
    * 32
* bus_width
    * 32

|name|offset_address|
|:--|:--|
|[SOURCE_ADDR_REG](#DMA_CSR-SOURCE_ADDR_REG)|0x00|
|[DEST_ADDR_REG](#DMA_CSR-DEST_ADDR_REG)|0x04|
|[LENGTH_REG](#DMA_CSR-LENGTH_REG)|0x08|
|[CONTROL_REG](#DMA_CSR-CONTROL_REG)|0x0c|
|[STATUS_REG](#DMA_CSR-STATUS_REG)|0x10|

### <div id="DMA_CSR-SOURCE_ADDR_REG"></div>SOURCE_ADDR_REG

* offset_address
    * 0x00
* type
    * default
* comment
    * Source Address for the DMA transfer.

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|addr|[31:0]|rw|0x00000000||||

### <div id="DMA_CSR-DEST_ADDR_REG"></div>DEST_ADDR_REG

* offset_address
    * 0x04
* type
    * default
* comment
    * Destination Address for the DMA transfer.

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|addr|[31:0]|rw|0x00000000||||

### <div id="DMA_CSR-LENGTH_REG"></div>LENGTH_REG

* offset_address
    * 0x08
* type
    * default
* comment
    * Transfer length in 32-bit words.

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|len|[15:0]|rw|0x0000||||

### <div id="DMA_CSR-CONTROL_REG"></div>CONTROL_REG

* offset_address
    * 0x0c
* type
    * default
* comment
    * Control register for the DMA.

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|go|[0]|custom<br>sw_read: default<br>sw_write: default<br>sw_write_once: false<br>hw_write: true<br>hw_set: false<br>hw_clear: false|0x0||||
|ie|[1]|rw|0x0||||

### <div id="DMA_CSR-STATUS_REG"></div>STATUS_REG

* offset_address
    * 0x10
* type
    * default
* comment
    * Status register for the DMA.

|name|bit_assignments|type|initial_value|reference|labels|comment|
|:--|:--|:--|:--|:--|:--|:--|
|busy|[0]|ro|||||
|done_if|[16]|w1c|0x0||||
