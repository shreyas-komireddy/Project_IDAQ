---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- Performs acquisition of ADC samples through the SPI interface.
-- Reads ADC data with one cycle latency, and  classifies it to output registers,
entity AD7384_ACQ is
 Port ( 
         clk_in     : in  std_logic;
         sys_rst    : in  std_logic;
         en         : in  std_logic;                               -- Enable Acquisition sequence 
         done       : out std_logic;                               -- Acquisition completion flag
         acq_cs     : out std_logic;
         acq_sclk   : out std_logic;
         acq_sdo_a  : in  std_logic;
         acq_sdo_b  : in  std_logic;
         acq_sdo_c  : in  std_logic;
         acq_sdo_d  : in  std_logic;
         bit_num    : in  unsigned(4 downto 0);
         ctrlr_reg  : in  std_logic_vector(7 downto 0);            -- Only (4 downto 3) are decoded to determine the AD7384_ACQ logic
         out_regA   : out std_logic_vector(31 downto 0);
         out_regB   : out std_logic_vector(31 downto 0)
      );
end AD7384_ACQ;

---- AD7384_ACQ Module Architecture
architecture Behavioral of AD7384_ACQ is

--- Instantiation of the SPI Interface Module
-- Used to shift out 16-bit command words to the AD7384.
component SPI_INTRFC is
 Port ( 
         clk_in    : in  std_logic;                         
         sys_rst   : in  std_logic;                         
         en        : in  std_logic;                         
         done      : out std_logic;                         
         cs        : out std_logic;                        
         sclk      : out std_logic;                         
         sdi       : out std_logic;                         
         sdo_a     : in  std_logic;
         sdo_b     : in  std_logic;
         sdo_c     : in  std_logic;
         sdo_d     : in  std_logic;
         rd_sdo    : in  std_logic;
         bit_num   : in  unsigned(4 downto 0);                         
         ctrlr_reg : in  std_logic_vector(7 downto 0);     
         dta_in    : in  std_logic_vector(15 downto 0);    
         spi_outA  : out std_logic_vector(15 downto 0);
         spi_outB  : out std_logic_vector(15 downto 0);
         spi_outC  : out std_logic_vector(15 downto 0);
         spi_outD  : out std_logic_vector(15 downto 0)
       );  
end component;

-- Internal Signals for SPI Interface
signal spi_en         : std_logic;
signal spi_done       : std_logic;
signal spi_rd_sdo     : std_logic;
signal dummy_dta_in   : std_logic_vector(15 downto 0);

signal tmp_outA       : std_logic_vector(15 downto 0);
signal tmp_outB       : std_logic_vector(15 downto 0);
signal tmp_outC       : std_logic_vector(15 downto 0);
signal tmp_outD       : std_logic_vector(15 downto 0);

--- Acquisition State Machine Definition
-- The FSM enables the SPI block to acquire the data and store.
type state_type is (IDLE, STRT_CONV, ACQ_DTA, FINISH);
signal acq_state: state_type := IDLE;

begin

--- SPI Interface Instantiation
INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in     => clk_in,
            sys_rst    => sys_rst,
            en         => spi_en,
            done       => spi_done,
            cs         => acq_cs,
            sclk       => acq_sclk,
            sdi        => open,
            sdo_a      => acq_sdo_a,
            sdo_b      => acq_sdo_b,
            sdo_c      => acq_sdo_c,
            sdo_d      => acq_sdo_d,
            rd_sdo     => spi_rd_sdo,
            bit_num    => bit_num,
            ctrlr_reg  => ctrlr_reg,
            dta_in     => dummy_dta_in,
            spi_outA   => tmp_outA,
            spi_outB   => tmp_outB,
            spi_outC   => tmp_outC,
            spi_outD   => tmp_outD
          );


--- Captures 16-bit ADC data at an user-controlled instance
CAPTURE_DTA: process(clk_in)
begin
 if rising_edge(clk_in) then
  if ctrlr_reg(4 downto 3) = "11" and acq_state = ACQ_DTA then 
     out_regA(15 downto 0)   <= tmp_outA;         ----- REG_A ==> Channel 0 & Channel 1 Data -----  
     out_regA(31 downto 16)  <= tmp_outB;       
     out_regB(15 downto 0)   <= tmp_outC;         ----- REG_B ==> Channel 2 & Channel 3 Data -----  
     out_regB(31 downto 16)  <= tmp_outD;
  end if;
 end if;
end process;

 -- Main Acquisition Process
-- Controls SPI read sequence and completion flag.
ACQ_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then   
        done <= '0';
        spi_en <= '0';
        spi_rd_sdo <= '0';
        acq_state <= IDLE; 
     else
        case acq_state is
        
          -- IDLE: Wait for 'en' to start acquisition
           when IDLE =>
             if en = '1' then 
                acq_state <= STRT_CONV;
             elsif en = '0' then
                done <= '0';
                spi_en <= '0';
                spi_rd_sdo <= '0';
             end if;
      
          -- STRT_CONV: Initiates the First Conversion 
           when STRT_CONV =>
             spi_en <= '1';
             if spi_done = '1' and spi_en /= '0' then
                spi_en <= '0';
                spi_rd_sdo <= '1';
                acq_state <= ACQ_DTA;
             end if;
       
          -- ACQ_DTA: Acquire the last converted data and initiates new conversion
           when ACQ_DTA =>
             spi_en <= '1';
             if spi_done = '1' and spi_en /= '0' then
                spi_en <= '0';
                spi_rd_sdo <= '1';
                acq_state <= FINISH;
             end if;
          
          -- FINISH: Assert done, wait for deassert of enable 
           when FINISH =>
             done <= '1';
             if en = '0' then
                acq_state <= IDLE;
                done <= '0';
                spi_rd_sdo <= '0';
             end if;
             
          -- Safety Fallback State
           when others =>
             acq_state <= IDLE;
        
       end case;
    end if;
 end if;
end process;

end Behavioral;
