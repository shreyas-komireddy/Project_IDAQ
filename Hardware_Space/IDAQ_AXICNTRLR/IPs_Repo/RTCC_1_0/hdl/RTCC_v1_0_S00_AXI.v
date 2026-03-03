`timescale 1 ns / 1 ps

	module RTCC_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
       // input [7:0] selections ,
        input  miso,
        output reg sclk,
        output  mosi,
        output reg cs,
      //  output reg [7:0] sec_reg,min_reg,hr_reg,week_reg,day_reg,month_reg,year_reg,
        output reg [7:0] rtc_data,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	 //******************General Registers***************************
        reg tmp_mosi=0;
        reg [3:0] time_registers=0;
        reg [7:0] opcode;
        
        
        //*******************SRAM Address and Data**********************
        reg [15:0] sram_address=16'h5f00;//16'h5fe1;
        reg [7:0] sram_data_write=8'b1111_0001;
        reg [15:0] delay_value=0;
        
        
        //***************************RTC_Address and Data***************        
        reg [7:0] rtc_data_write;
        reg [7:0] rtc_address=8'b0000_1001;                                                                 //minutes 8'b0000_1010;//seconds 8'b0000_1001;
        reg [7:0]rtc_flags=8'b0000_0000;                                                                    // address of the R_bit and W_bit flags in RTC_Registers mapping
 
        //*************************counters used in code ***************       
        reg [3:0] mclk_count;
        reg [ 3:0] W_R_count;
        reg [7:0] cs_count =7 ;
        reg [7:0] read_count=7;
        reg [23:0]ms_counter=0;        
        reg [3:0] counter=0;
        
        //*************************Information Flags********************
        
        reg p1_flag,p2_flag,p3_flag,p4_flag,p5_flag,p6_flag;
        reg wren_done_flag=0,soft_store_flag=0,store_flag=0;                                                  //states_flags
        reg sram_w_flag=0,sram_r_flag=0,rtc_write_flag=0,auto_store_flag=0,recall_flag=0;
        reg sram_address_flag=0,sram_data_flag=0;                                                           //sram_flags
        
        reg [7:0] sec_reg=0,min_reg=0,hr_reg=0,week_reg=0,day_reg=0,month_reg=0,year_reg=0;
        reg rtc_R_flag=0,rtc_A_flag=0,rtc_W_flag=0;                                                         //rtc_flags
        reg R_bit_OFF=0,R_bit_ON=0,W_bit_OFF=0,W_bit_ON=0;                                                 // R_bit and W_bit flags
        reg WO_bit_finish;
        reg [7:0] RTC_read_count=6;
        
        
        reg w_r_flag=0,read_block_flag=0,sram_read_block_flag=0;        
        reg cs_flag=1,delay_count=0,start_shifting=0,nine_flag=0,ten_flag=0;
        reg sram_W_on=0,sram_R_on=0;        
        reg oscf_bit_flag=0, oscf_done=0;


        //************************OPERATING STATES**********************
        localparam WREN   = 1,
                  SRAM_W = 2,
                  SRAM_R = 3,
                  RTC_W  = 4,
                  RTC_R  = 5,
                  AUTO_S = 6,
                  RECALL = 7,
                  STORE  = 8,
                  RTC_R_bits = 9,
                  RTC_W_bits =10,
                  second_delay = 11,
                  one_ms_delay = 12,
                  Delay_S_R = 13,
                  oscf_bit = 14,
                  wren_wrtc = 15; 
                  
        reg [4:0] state;
        
        //  data of time,date,day,week for RTC_WRITE ======= 
//        reg [7:0]seconds = 8'b00110100;//34 sec
//        reg [7:0]Minutes = 8'b00000110;// 06 minutes
//        reg [7:0]hours   = 8'b00000001;//1st hour
//        reg [7:0]week    = 8'b00000100;// 4 th day of week
//        reg [7:0]Day     = 8'b00010000;//10th date
//        reg [7:0]Months  = 8'b00000110;//6th month
//        reg [7:0]years   = 8'b00000001;//1st year
	//------------------------------------------------
	//-- Number of Slave Registers 6
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      //slv_reg3 <= 0;
	      //slv_reg4 <= 0;
	      //slv_reg5 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	        /*  3'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  */
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      //slv_reg3 <= slv_reg3;
	                      //slv_reg4 <= slv_reg4;
	                      //slv_reg5 <= slv_reg5;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= slv_reg1;
	        3'h2   : reg_data_out <= slv_reg2;
	       // 3'h3   : reg_data_out <= slv_reg3;
	       3'h3 :
	        begin
	           reg_data_out[7:0]<=sec_reg;
	           reg_data_out[15:8]<=min_reg;
	           reg_data_out[23:16]<=hr_reg;
	           reg_data_out[31:24]<=week_reg; end
	        //3'h4   : reg_data_out <= slv_reg4;
	        3'h4   : begin
	                   reg_data_out[7:0]<=day_reg;
                       reg_data_out[15:8]<=month_reg;
                       reg_data_out[23:16]<=year_reg;
                       reg_data_out[31:24]<=8'b00000000; end
	        3'h5   : reg_data_out <= slv_reg5;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
    
	// User logic ends
	assign mosi = tmp_mosi;
      always@(posedge S_AXI_ACLK or negedge S_AXI_ARESETN)begin
            if(!S_AXI_ARESETN)begin
                cs<=1;
                sclk<=0;  
                delay_count<=0;       
                mclk_count<=0;end
            else begin
                mclk_count<=mclk_count+1; 
                   
                     if(cs_flag==1 & mclk_count==0)begin
                            cs<=1;end
                     else if(sclk==0 & mclk_count==0) begin
                            cs<=0;end  
                        
                    if(mclk_count==2 & sclk==0 )begin
                        delay_count<=1;end
                    else if(mclk_count==0 & sclk==1 ) begin
                        delay_count<=0;end
  
                    if(mclk_count== 3)begin
                        sclk<=~sclk;               
                        mclk_count<=0;end end end
         
 //=====================================Statemachine start here==========================================
always@(negedge sclk or negedge S_AXI_ARESETN ) begin
    if(!S_AXI_ARESETN)begin                                                                  //During RESET all Flags are reset to initial values 
        rtc_write_flag<=0;
        sram_read_block_flag<=0;
        read_block_flag<=0;            
        w_r_flag<=0;
        W_R_count<=0;
        sram_data_flag<=0;
        sram_address_flag<=0;
        soft_store_flag<=0;
        store_flag<=0;      
        wren_done_flag<=0;           
        rtc_A_flag <=0;
        rtc_R_flag <=0;  
        rtc_W_flag<=0; 
        R_bit_OFF<=0;
        R_bit_ON<=0;
        W_bit_OFF<=0;
        W_bit_ON<=0;
        p1_flag<=0;
        p2_flag<=0;
        p3_flag<=0;
        p4_flag<=0;
        p5_flag<=0;
        p6_flag<=0;
        state<= 11;
        opcode<=0;
        cs_flag<=1;  
        nine_flag<=0; 
        ten_flag<=0;   
        sram_W_on<=0; 
        WO_bit_finish<=0;       
        cs_count<=7;   
        time_registers<=0;end    
    
    else begin                                                                        //States strat from here  
        case(state)    
    //======================================Auto_Store Case================================================                      
        AUTO_S : begin
             cs_flag<=0;
             start_shifting<=1;
                if(wren_done_flag==1 )begin                                            //this Auto_Store will execute only after enable of WEN otherwise it wil go to WREN state
                    opcode<=8'b0001_1001;                                            //8'b0001_1001 auto_store opcode  to disable //8'b0101_1001 to enable the auto store
                    if(cs_count == 0 && cs==0)begin
                        cs_flag<=1;
                        cs_count <=  7;
                        start_shifting<=0;
                        wren_done_flag<=0;
                        soft_store_flag<=1;
                       // auto_store_flag<=0;--------------
                        state <= STORE;end 
                    else if(cs==0)begin                        
                        cs_count<=cs_count - 1;
                        state <= AUTO_S;end end 
                else begin                    
                    opcode<=8'b0000_0110;                                             //wren opcode
                    state<= WREN;end end                                             //sending back to WREN to enable WEN bit            
    //====================================Enabling the Write Bit WREN Case =======================================       
            WREN : begin
                                  
               store_flag<=0;
               cs_flag<=0;
                start_shifting<=1;
                if(cs_count == 0 & cs==0)begin                
                        cs_count <= 7;
                        cs_flag<=1;
                        start_shifting<=0;    
                        wren_done_flag<=1;
                    if(soft_store_flag==0 & auto_store_flag == 1)begin
                        state<=AUTO_S; end
                    else if(store_flag==0 & soft_store_flag==1)begin                      
                        state<=STORE; end
                    else if( store_flag==1 & ( sram_w_flag!=1 & sram_r_flag !=1 & rtc_write_flag !=0 &   auto_store_flag !=1))begin                      
                        state<= RTC_R ; end                                           //going to RTC_READ
                    else if(sram_w_flag==1 )begin   
                        sram_w_flag<=0;             
                        state<=SRAM_W; end
                    else if( recall_flag==1) begin
                        recall_flag<=0;
                        state<=RECALL;end
                    else if(rtc_R_flag==1 & w_r_flag==0 )begin                                       
                        R_bit_ON<=1;                                                                
                        state<= RTC_R_bits;end
                    else if(rtc_R_flag==0 & w_r_flag==0) begin  
                        R_bit_OFF<=1;
                        state<=RTC_R_bits; end
                    else if(rtc_W_flag==1 & w_r_flag==1)begin
                        W_bit_ON<=1;                       
                        rtc_W_flag<=0;
                        state<= RTC_W_bits; end 
                    else if(rtc_W_flag==0 & w_r_flag==1) begin  
                        W_bit_OFF<=1;
                        state<=RTC_W_bits; end end 
                else if(cs==0)begin
                        cs_count<=cs_count - 1;//end
                        state <= WREN;end end 
            
    //========================== Store Case ==================================================             
            STORE : begin                                                             //store execute only when the autostore executed
                  cs_flag<=0;
                  start_shifting<=1;                
                if(wren_done_flag==1)begin                                            //this Store will execute only after enable of WEN otherwise it wil go to WREN state 
                    opcode<=8'b0011_1100;                                             //store opcode
                    if(cs_count == 0&& cs==0)begin
                        cs_flag<=1;
                        cs_count <=  7;
                        wren_done_flag<=0;                       
                        store_flag<=1;
                        soft_store_flag<=0;
                       // auto_store_flag<=0;--------------
                        start_shifting<=0;
                        delay_value<=100000;
                        state <= Delay_S_R;end 
                    else if(cs==0)begin
                        cs_count<=cs_count - 1;
                        state <= STORE;end end 
                else begin
             
                    opcode<=8'b0000_0110;                                             //wren opcode
                    state<= WREN;end end                                              //sending back to WREN to enable WEN bit
      //===========================SRAM_Write Case=======================================
            SRAM_W : begin 
               cs_flag<=0;
               start_shifting<=1; 
               
                 if(wren_done_flag==1 )begin                                          //this SRAM_WRITE will execute only after enable of WEN otherwise it wil go to WREN state
                     opcode<=8'b0000_0010;                                            //sram_write opcode
                     sram_W_on<=1;
                    if(cs_count == 0&& cs==0)begin                                         
                      if(sram_address_flag==0) begin                                       //after completion of opcode rise a flag to send the 2bytes address
                        sram_address_flag<=1;                        
                        cs_count<=15;
                        state<=SRAM_W;end  
                         
                      else if( sram_address_flag==1 & sram_data_flag== 0) begin                 //after completion of  sending address it will rise a data_flag to write data                       
                        sram_data_flag<=1;
                        cs_count<=7;
                        state<=SRAM_W;  end    
                        
                      else if(sram_data_flag==1) begin                                     //it indicates the SRAM_WRITE is completed      
                                         
                        cs_flag<=1;
                        wren_done_flag<=0;
                        sram_address_flag<=0;
                        sram_data_flag<=0;                       
                        sram_W_on<=0;
                        start_shifting<=0;                      
                        sram_w_flag<=0;
                        state<=second_delay;
                        cs_count<=7;end end 
                        
                    else if(cs==0) begin
                        cs_count<=cs_count -1;
                        state <= SRAM_W; end end //end 
                 else begin
                     opcode<=8'b0000_0110;                                            //wren opcode
                     state<= WREN;end end                                            //sending back to WREN to enable WEN bit
                     
                     
      //===================================SRAM_Read Case=====================
           SRAM_R :begin
            
               cs_flag<=0;
               start_shifting<=1;
               // if(sram_r_flag==1 )begin                                           //this SRAM_Read will execute only after enable of WEN otherwise it wil go to WREN state 
                    opcode<= 8'b0000_0011;
                    sram_R_on<=1;
                    if(cs_count == 0&& cs==0)begin                                         
                          if(sram_address_flag==0) begin                                   //after completion of opcode rise a flag to send the 2bytes address to read the data 
                            sram_address_flag<=1;                           
                            cs_count<=15;                                             // here the only the 8 bits turns to 16 bits to read 
                            state<=SRAM_R;end   
                            
                          else if( sram_address_flag==1 & sram_data_flag== 0) begin             //after completion of  sending address it will rise a data_flag to Read data                          
                            sram_data_flag<=1;
                            state<=SRAM_R;  
                            sram_read_block_flag<=1;                       
                            cs_count<=7;end
                            
                          else if(sram_data_flag==1) begin                                 //it indicates the SRAM_Read is completed                      
                            cs_flag<=1;
                            wren_done_flag<=0;
                            sram_address_flag<=0;
                            sram_data_flag<=0;                           
                            sram_read_block_flag<=0;                            
                            start_shifting<=0;
                            sram_R_on<=0;    
                            if(slv_reg0 ==32'd4)begin state<=SRAM_R;end
                            else begin state<=second_delay; end                            
                            cs_count<=7;end end                  
                    
                    else if(cs==0) begin         
                            cs_count<=cs_count -1;
                             state <= SRAM_R; end
 end     
 
    
 //===============================RTC_R_bits Case=========================================
            RTC_R_bits : begin  
                cs_flag<=0;
                start_shifting<=1;                         //executes starting and ending of the RTC_R because this enables and disables the R bit 
                if(wren_done_flag==1 )begin   
               opcode<=8'b0001_0010;                                             //write_opcode============               
                if(cs_count == 0&& cs==0)begin                                
                    cs_count<=7;//-------------------------------------------------------------------------------------------------------------------------------------------------
                    W_R_count <= W_R_count+1;
                    
                    //****************** R_bit enabling*********************
                    if(R_bit_ON==1)begin                                              //set a R bit address, this execute before rtc read
                        if(W_R_count==1) begin
                            rtc_flags<=8'b0000_0001;                                  //opcode makes R bit enable
                            state<=RTC_R_bits;end
                        else if(W_R_count == 2)begin
                            cs_flag<=1;
                            R_bit_ON<=0;
                            nine_flag<=1;                           
                            W_R_count<=0;
                            rtc_flags<=8'b0000_0000;                                  //passing the RTC_flag Register
                            rtc_R_flag<=0;
                            opcode<=8'b0001_0011;                                     //Read_rtc opcode
                            start_shifting<=0;                            
                            state<=RTC_R;end end 
                            
                  //*************R_bit disabling *******************************       
                    else if(R_bit_OFF==1)begin                                        //clear a R bit address,this executes after the rtc read 
                        if(W_R_count==1) begin
                            rtc_flags<=8'b0000_0000;                                  //opcode makes R bit Disable
                            state<=RTC_R_bits;end
                        else if(W_R_count == 2)begin                                
                            cs_flag<=1;
                            start_shifting<=0;
                            R_bit_OFF<=0;                                                       
                            W_R_count<=0;
                            rtc_flags<=8'b0000_0000;                                  //passing the RTC_flag Register  
                            wren_done_flag<=0;
                            rtc_R_flag<=0;
                        
                        //=================here all the selection of the operation are done =====================
                          if( slv_reg0 == 32'd3)begin                                     //===========to enable the sram_write======                               
                                sram_r_flag<=0;
                                rtc_write_flag<=0;
                                auto_store_flag<=0;   
                                 recall_flag<=0; 
                                 soft_store_flag<=0;    
                                 p2_flag <=0;                              
                                 p3_flag<=0;
                                 p4_flag<=0;
                                 p5_flag<=0;
                                 p6_flag<=0;
                                if(p1_flag==0) begin
                                    p1_flag<=1;
                                     sram_w_flag<=1;
                                    state<=2;end end
                                    
                            else if(slv_reg0 ==32'd2 )begin                                 //======== to enable the sram_read=========
                                    sram_w_flag<=0;                                   
                                    auto_store_flag<=0;
                                    rtc_write_flag<=0;
                                    recall_flag<=0; 
                                    soft_store_flag<=0; 
                                     p1_flag<=0;                                     
                                     p3_flag<=0;
                                     p4_flag<=0;
                                     p5_flag<=0;
                                     p6_flag<=0;
                                    if(p2_flag==0) begin
                                        p2_flag<=1;
                                        sram_r_flag<=1;                                       
                                        state<=3;end    end 
                                        
                            else if(slv_reg0 == 32'd1 && rtc_write_flag==0)begin                                 //======== to enable the rtc_write=========
                                    sram_w_flag<=0;
                                    sram_r_flag<=0;
                                  //  rtc_write_flag<=1;----------------------
                                    auto_store_flag<=0;                                    
                                    recall_flag<=0;  
                                    soft_store_flag<=0;
                                     p1_flag<=0;     
                                     p2_flag<=0;                                  
                                     p4_flag<=0;
                                     p5_flag<=0;
                                     p6_flag<=0;
                                    if(p3_flag==0) begin
                                        p3_flag<=1;
                                        w_r_flag<=1;
                                        rtc_write_flag<=1;
                                        state<=4;end end
                                        
                            else if(slv_reg0 == 32'd6 && auto_store_flag==0)begin                                 //======== to enable the AUTO_STORE=========
                                    sram_w_flag<=0;
                                    sram_r_flag<=0;
                                    rtc_write_flag<=0;                                   
                                    recall_flag<=0;  
                                    soft_store_flag<=0;
                                     p1_flag<=0;
                                     p2_flag<=0;  
                                     p3_flag<=0;                                    
                                     p5_flag<=0;
                                     p6_flag<=0;
                                     if(p4_flag==0)begin
                                        auto_store_flag<=1;
                                        state<=6; 
                                        p4_flag<=1;end end 
                                        
                            else if(slv_reg0 == 32'd7)begin                                 //======== to enable the RECALL=========
                                    sram_w_flag<=0;
                                    sram_r_flag<=0;
                                    rtc_write_flag<=0;
                                    auto_store_flag<=0;                                    
                                    soft_store_flag<=0;
                                     p1_flag<=0;
                                     p2_flag<=0;  
                                     p3_flag<=0;
                                     p4_flag<=0;                                   
                                     p6_flag<=0;
                                    if(p5_flag==0)begin
                                        p5_flag<=1;
                                        recall_flag<=1;
                                        state<=7;end  end
                            
                            else if(slv_reg0 == 32'd8 )begin                                 //======== to enable the SOFT_STORE=========
                                    sram_w_flag<=0;
                                    sram_r_flag<=0;
                                    rtc_write_flag<=0;
                                    auto_store_flag<=0;
                                    recall_flag<=0;
                                     p1_flag<=0;
                                     p2_flag <=0;  
                                     p3_flag<=0;
                                     p4_flag<=0;
                                     p5_flag<=0;                                    
                                   if(p6_flag==0)begin
                                        soft_store_flag<=1;
                                        p6_flag<=1;
                                        state<=8;end end
                            else  begin                                               //if no operation is selected or after the completion any operation then it will goes to Rtc_Read
                                     sram_r_flag<=0;
                                     sram_w_flag<=0;
                                     rtc_write_flag<=0;//-------------------------
                                    // auto_store_flag<=0; -----------------------
                                     soft_store_flag<=0;
                                     recall_flag<=0; 
                                     p1_flag<=0;
                                     p2_flag<=0;
                                     p3_flag<=0;
                                     p4_flag<=0;
                                     p5_flag<=0;
                                     p6_flag<=0; 
                                     state<= second_delay; end end  end end   
                                     
                                      
                else if(cs==0) begin 
                     cs_count<=cs_count-1;
                     state<=RTC_R_bits;end end  
         
         else begin
            state<=second_delay;end end
          
           
            RTC_W_bits : begin//==================executes starting and ending of the RTC_W because this enables and disables the W bit ============               
               //  read_block_flag<=0;
                cs_flag<=0;
                start_shifting<=1;
                opcode<=8'b0001_0010;                                                 //write_opcode              
                if(cs_count == 0&& cs==0)begin
                         cs_count<=7;
                         W_R_count <= W_R_count+1;
                         if(W_bit_ON==1)begin
                          WO_bit_finish<=1; 
                          //********************W_bit enabling*************************
                            if(W_R_count==1) begin 
                                WO_bit_finish<=0;
                                rtc_flags<=8'b0000_0010;                              // opcode makes W bit enable
                                state<=RTC_W_bits;end
                             else if(W_R_count == 2)begin
                              
                               WO_bit_finish<=0;
                                cs_flag<=1;
                                start_shifting<=0;                                
                                W_bit_ON<=0;                           
                                W_R_count<=0;
                                rtc_flags<=8'b0000_0000;                              // passing the RTC_flag Register  
                                rtc_W_flag<=0;
                                ten_flag<=1;
                            
                                if(oscf_bit_flag==0 & oscf_done ==0 )begin
                                    oscf_bit_flag<=1;
                                    state <= oscf_bit;end
                                else begin
                                    state<=wren_wrtc;end//RTC_W
                               end   end
                         //******************W_bit Disabling**************************
                         else if(W_bit_OFF==1)begin
                            WO_bit_finish<=1; 
                            if(W_R_count==1) begin
                                WO_bit_finish<=0; 
                                rtc_flags<=8'b0000_0000;                              //opcode makes W bit disable
                                state<=RTC_W_bits;end                                
                             else if(W_R_count == 2)begin                     
                                WO_bit_finish<=0; 
                                cs_flag<=1; 
                                start_shifting<=0;
                                W_bit_OFF<=0;                           
                                W_R_count<=0;
                                rtc_flags<=8'b0000_0000;                              // passing the RTC_flag Register
                                wren_done_flag<=0;
                                rtc_W_flag<=0;                              
                                w_r_flag<=0;                               
                               // rtc_write_flag<=0;---------------------------------
                                state<=one_ms_delay;end end end 
                                             
                else if(cs==0)begin                    
                                           
                     cs_count<=cs_count-1;
                     state<=RTC_W_bits;end end
           
      //========================RTC_Read Case==================================            
            RTC_R : begin

                cs_flag<=0;
                start_shifting<=1;
                 if(wren_done_flag==1 )begin                                            //this RTC_Read will execute only after enable of WEN otherwise it wil go to WREN state
                    opcode<=8'b0001_0011;  //Read_rtc opcode
                                                          
                    if(cs_count == 0&& cs==0)begin                        
                        if(rtc_R_flag ==0) begin                                      //executes after the passing the opcode onto mosi                          
                         
                            rtc_R_flag<=1;
                            cs_count<=7;//-----------------
                            
                            state<=RTC_R; end 
                        else if( rtc_R_flag==1 & rtc_A_flag==0)begin                  //executes after passing the starting address of the RTC_Read
                          
                            cs_count<=7;//----------------------------
                            rtc_A_flag<=1;
                            read_block_flag<=1;
                            
                            state<=RTC_R;end
                       else if(rtc_R_flag==1 & rtc_A_flag==1) begin                   //executes after reading the 16 registers 
                            if(RTC_read_count==0)begin
                                cs_count<=7;//--------------------------
                                cs_flag<=1; 
                                start_shifting<=0;                              
                                rtc_A_flag<=0;
                                RTC_read_count<=6;
                                read_block_flag<=0;
                                wren_done_flag<=0;
                                opcode<=8'b0000_0110;  //================modified======
                                state<=RTC_R;end
                               else begin  RTC_read_count<=RTC_read_count-1;cs_count<=7; end 
                       end
                            else begin
                                cs_count<=7;//------------------------------------------------                              
                                state<=RTC_R;end end
                   
                    else if(cs==0) begin                       
                            cs_count<=cs_count - 1; 
                            state<=RTC_R; 
                             end end                  
                else begin
                    if(rtc_R_flag==0)begin
                        rtc_R_flag<=1;end
                    else if(rtc_R_flag ==1) begin
                         rtc_R_flag<=0; end  
                         cs_flag<=0; 
                         opcode<=8'b0000_0110;//00000110==============modified===============   
                         start_shifting<=1;    
                         nine_flag<=0;                                        
                        state<=WREN; end end
                  
      //===================================== RTC_Write Case ===================================   
           RTC_W : begin
           
           // read_block_flag<=0;
                cs_flag<=0;
                start_shifting<=1;
                if(wren_done_flag==1)begin                                            //this RTC_Write will execute only after enable of WEN otherwise it wil go to WREN state 
                    opcode<=8'b0001_0010;                                             //Write_rtc opcode
                    if(cs_count == 0&& cs==0)begin
                        if(rtc_W_flag ==0) begin                                       //executes after the passing the opcode onto mosi
                         
                            rtc_W_flag<=1;
                            cs_count<=7;
                            state<=RTC_W; end 
                        else if( rtc_W_flag==1 & rtc_A_flag==0)begin                  //executes after passing the starting address of the RTC_Write
                          
                            cs_count<=7;
                            rtc_A_flag<=1;                            
                            state<=RTC_W; end 
                        else if(rtc_W_flag==1 & rtc_A_flag== 1 )begin                 //executes after Writing the 16 registers
                            
                            //cs<=1;
//                            cs_flag<=1;                              
//                            start_shifting<=0;
//                            cs_count<=7;                           
//                            rtc_A_flag<=0;
//                            wren_done_flag<=0;
//                            state<=RTC_W;
                               if(time_registers==6)begin//==============================modified  for all time registers 
                              
                                  cs_flag<=1;
                                    start_shifting<=0;
                                    cs_count<=7;  
                                    time_registers<=0;                         
                                    rtc_A_flag<=0;
                                     wren_done_flag<=0;
                                    state<=RTC_W; end  
                                    else begin//==========start 
                                     time_registers<= time_registers + 1;
                                            
                                       cs_count<=7; end //=============================================upto here
                                        end end          
                    else if(cs==0) begin                       
                            cs_count<=cs_count -1;
                            state<=RTC_W;end end// end
                else begin
                    if(rtc_W_flag==0)begin
                        rtc_W_flag<=1;end
                    else if(rtc_W_flag ==1) begin
                         rtc_W_flag<=0; end  
                    // rtc_write_flag<=1;-------------------------
                      w_r_flag<=1;
                    opcode<=8'b0000_0110;//=========modified======= 
                    ten_flag<=0;                                 
                    state<=WREN; end
                end
      //==========================RECALL Case ==============================
              RECALL : begin                                                          //RECALL execute only when the RECALL is called manually otherwise every power up the internal RECALL will execute automatically
               
              
                 cs_flag<=0;
                 start_shifting<=1;
                 if(wren_done_flag==1)begin                                            //this SRAM_WRITE will execute only after enable of WEN otherwise it wil go to WREN state
                    opcode<=8'b0110_0000;                                             //RECALL opcode
                    if(cs_count == 0 && cs==0)begin
                    
                        cs_flag<=1; 
                        start_shifting<=0;
                        cs_count <=  7;
                        wren_done_flag<=0;                       
                        store_flag<=1;
                      //  auto_store_flag<=0;---------------------------
                        delay_value<=6666;
                        state <= Delay_S_R;end 
                    else if(cs==0) begin
                        
                        cs_count<=cs_count - 1;
                        state <= RECALL;end end 
                else begin
                    opcode<=8'b0000_0110;                                             //wren opcode
                    state<= WREN;end end                                             //sending back to WREN to enable WEN bit
             
             
             
             second_delay: begin
                    if(ms_counter==1593750)begin//1700000--102 ms for 100MHz   , 1593750 for 125MHz
                        counter<=counter+1;
                        ms_counter<=0;
                        if(counter==9)begin
                            counter<=0;                           
                            state<=RTC_R;end
                    end
                    else begin
                        ms_counter<=ms_counter+1;end
             end
             
             
          one_ms_delay : begin
                    if(ms_counter==16666)begin//13333 for 0.8 ms for rtc write 
                        ms_counter<=0;
                         if(oscf_bit_flag==1)begin oscf_bit_flag <=0; oscf_done=1; state<=RTC_W; end 
                                else begin state <=RTC_R; end
                     end
                     else begin
                        ms_counter<=ms_counter+1;end
         end
         Delay_S_R : begin          //  6ms delay after the store opcode (100000)   
                    if(ms_counter==delay_value)begin
                        ms_counter<=0;
                        state<=RTC_R;end
                     else begin
                        ms_counter<=ms_counter+1;end        
         
         end
         
    
        oscf_bit : begin
                cs_flag<=0;
                start_shifting<=1;
               if(wren_done_flag==1)begin 
                    opcode<=8'b0001_0010;                                             //Write_rtc opcode
                    if(cs_count == 0&& cs==0)begin
                        if(rtc_W_flag ==0) begin                                      //executes after the passing the opcode onto mosi
                       
                            rtc_W_flag<=1;
                            cs_count<=7;
                            state<=oscf_bit; end 
                        else if( rtc_W_flag==1 & rtc_A_flag==0)begin                  //executes after passing the starting address of the RTC_Write
                            
                            cs_count<=7;
                            rtc_A_flag<=1;                            
                            state<=oscf_bit; end 
                        else if(rtc_W_flag==1 & rtc_A_flag== 1 )begin     
                                  cs_flag<=1;
                                    start_shifting<=0;
                                    cs_count<=7;  
                                    time_registers<=0;                         
                                    rtc_A_flag<=0;
                                     wren_done_flag<=0;
                                    state<=oscf_bit; end    end        
                    else if(cs==0) begin
                            cs_count<=cs_count -1;
                            state<=oscf_bit;end end
                else begin
                    if(rtc_W_flag==0)begin
                        rtc_W_flag<=1;end
                    else if(rtc_W_flag ==1) begin
                         rtc_W_flag<=0; end  
                   //  rtc_write_flag<=1;----------------------
                      w_r_flag<=1;
                    opcode<=8'b0000_0110;//=========modified======= 
                    ten_flag<=0;                                 
                    state<=WREN; end
                end 
                   
       wren_wrtc : begin
                   
                     opcode<=8'b0000_0110;
                     cs_flag<=0;                   
                     start_shifting<=1;                                        //wren opcode
                    if(cs_count == 0 && cs==0)begin
                         cs_flag<=1;
                        cs_count <=  7;
                        start_shifting<=0;
                       
                        state <= RTC_W;end 
                    else if(cs==0)begin                      
                        cs_count<=cs_count - 1;                     
                        state <= wren_wrtc;end 
         end
       
       
      //==================Default Case ====================================          
            default: begin
                state <= RTC_R; end
           
   endcase
   end end
   
 //==================================READING all the RTC and SRAM Data on POSEDGE of SCLK==================================
 always@(negedge sclk or negedge S_AXI_ARESETN) begin                                                          //reciving the data from the miso on posedge of the sclk 
     if(!S_AXI_ARESETN) begin      
        rtc_data<=0;
       
        read_count<=7; end
        else begin
                if((read_block_flag==1 && cs==0) & slv_reg0 !=32'd2 )begin   //                                           //Reading the RTC_Data
                     //rtc_data[read_count]<=miso;
                      if(RTC_read_count==6)begin sec_reg[read_count]<=miso;rtc_data[read_count]<=sec_reg[read_count];  end
                      else if(RTC_read_count==5)begin min_reg[read_count]<=miso;  end
                    else if(RTC_read_count==4)begin hr_reg[read_count]<=miso; end
                    else if(RTC_read_count==3)begin week_reg[read_count]<=miso; end
                    else if(RTC_read_count==2)begin day_reg[read_count]<=miso; end
                    else if(RTC_read_count==1)begin month_reg[read_count]<=miso; end                    
                    else begin year_reg[read_count]<=miso; end//if(RTC_read_count==0)

                    if(read_count==0)begin                  
                        read_count<=7;end
                    else begin
                        read_count<=read_count -1; end
                end
             else if(sram_read_block_flag==1 & slv_reg0 ==32'd2 ) begin                                           //Reading SRAM_Data
               
                rtc_data[read_count] <= miso;
                if(read_count==0)begin
                    read_count<=7;end
                else begin
                    read_count<=read_count -1; end
                end end
         end
 //=================================== 
 /*
 always@(posedge delay_count  or negedge mrst)begin
     if(!mrst)begin  
         flag_test<=0;end
    else if(start_shifting==1 )begin   
         
            if((R_bit_ON==0 | R_bit_OFF==0) & W_R_count==0 &  nine_flag==0 & ten_flag==0 & sram_R_on==0 & sram_W_on ==0  & WO_bit_finish==0 ) begin//& rtc_R_flag==0
//               if(wren_done_flag==0)begin
                write_address_flag<=1;
                tmp_mosi<=opcode[cs_count]; end
                
            else if(R_bit_ON==1 | R_bit_OFF==1) begin                        //sends the flag_register address
                tmp_mosi<=rtc_flags[cs_count]; end
                
            else  if(W_R_count==2)begin
                
                tmp_mosi<=rtc_flags[cs_count];end 
                
             else if(rtc_R_flag == 1 && rtc_A_flag==0) begin                //passing the starting address to READ the RTC_Data here in this NVSRAM the we have to pass the starting address then it read all the 16 registers data by incrementing address by itself
               tmp_mosi<=rtc_address[cs_count]; end 
                   
             else if(address_flag==1 & data_flag==0 & (sram_W_on==1 | sram_R_on==1)) begin                 //here it will send 2bytes address
               
                tmp_mosi<=sram_address[cs_count];end
               
               
              else if(data_flag==1 & sram_W_on==1) begin                                   //here it will send data to write on to the sram
                 
                tmp_mosi<=data_write[cs_count];end
                
               else if((W_bit_ON==1 | W_bit_OFF==1 )& WO_bit_finish==1) begin                        //sends the flag_register address
                        tmp_mosi<=rtc_flags[cs_count]; end 
                           
                else if(W_R_count==2 & ten_flag==1)begin       
                        flag_test<=1;                                //sends the W_bit enable opcode     
                        tmp_mosi<=rtc_flags[cs_count];end
                else if(rtc_W_flag == 1 & rtc_A_flag==0) begin                //passing the starting address to Write the RTC_Data here in this NVSRAM the we have to pass the starting address then it read all the 16 registers data by incrementing address by itselg====
                       
                       tmp_mosi<=rtc_address[cs_count]; end
                 else if(rtc_W_flag == 1 & rtc_A_flag==1 ) begin
                       
                        tmp_mosi<=rtc_data_write[cs_count];end
            else begin            
              tmp_mosi<=opcode[cs_count];end
    end
  end*///this is original 
  
 always@(posedge delay_count)begin    
     if(start_shifting==1 )begin   
         
            if((R_bit_ON==0 | R_bit_OFF==0) & W_R_count==0 &  nine_flag==0 & ten_flag==0 & sram_R_on==0 & sram_W_on ==0  & WO_bit_finish==0 ) begin//& rtc_R_flag==0              
                tmp_mosi<=opcode[cs_count]; end
                
            else if(R_bit_ON==1 | R_bit_OFF==1) begin                        //sends the flag_register address
                tmp_mosi<=rtc_flags[cs_count]; end
                
            else  if((R_bit_ON==1 | R_bit_OFF==1) & W_R_count==2)begin
                 
                tmp_mosi<=rtc_flags[cs_count];end 
                
             else if(rtc_R_flag == 1 && rtc_A_flag==0) begin                //passing the starting address to READ the RTC_Data here in this NVSRAM the we have to pass the starting address then it read all the 16 registers data by incrementing address by itself
               tmp_mosi<=rtc_address[cs_count]; end 
                   
             else if(sram_address_flag==1 & sram_data_flag==0 & (sram_W_on==1 | sram_R_on==1)) begin                 //here it will send 2bytes address
               
                tmp_mosi<=sram_address[cs_count];end
               
               
              else if(sram_data_flag==1 & sram_W_on==1) begin                                   //here it will send data to write on to the sram
                 
                tmp_mosi<=sram_data_write[cs_count];end
                
               else if((W_bit_ON==1 | W_bit_OFF==1 )& WO_bit_finish==1) begin                        //sends the flag_register address
                        
                        tmp_mosi<=rtc_flags[cs_count]; end 
                           
                else if((W_bit_ON==1 | W_bit_OFF==1 )& W_R_count==2 )begin       
                                                      //sends the W_bit enable opcode     
                        tmp_mosi<=rtc_flags[cs_count];end
               else if(rtc_W_flag == 1 & rtc_A_flag==0) begin                //passing the starting address to Write the RTC_Data here in this NVSRAM the we have to pass the starting address then it read all the 16 registers data by incrementing address by itselg====
                       
                      // tmp_mosi<=rtc_address[cs_count]; end
                       if(oscf_bit_flag==1)begin tmp_mosi<= rtc_flags[cs_count];end
                       else begin tmp_mosi<=rtc_address[cs_count]; end
                end
                 else if(rtc_W_flag == 1 & rtc_A_flag==1 ) begin                       
                       // tmp_mosi<=rtc_data_write[cs_count];end
                       if(time_registers==1)begin rtc_data_write<=slv_reg1[15:8];end//min
                                            else if(time_registers==2) begin rtc_data_write<= slv_reg1[23:16]; end//hr
                                            else if(time_registers==3) begin rtc_data_write<= slv_reg1[31:24]; end//week
                                            else if(time_registers==4) begin rtc_data_write<= slv_reg2[7:0]; end//day
                                            else if(time_registers==5) begin rtc_data_write<= slv_reg2[15:8]; end//months
                                            else if(time_registers==6) begin rtc_data_write<= slv_reg2[23:16]; end//years
                                            else begin  rtc_data_write<=slv_reg1[7:0];end//sec
                       if(oscf_bit_flag==1)begin tmp_mosi<= rtc_flags[cs_count]; end
                       else begin tmp_mosi<=rtc_data_write[cs_count];end
                end
            else begin            
              tmp_mosi<=opcode[cs_count];end
    end
  end
	endmodule