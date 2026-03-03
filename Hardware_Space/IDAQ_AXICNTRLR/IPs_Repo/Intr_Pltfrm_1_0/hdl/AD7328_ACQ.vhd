---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- Performs acquisition of ADC samples through the SPI interface.
-- Reads channel information + ADC data, classifies it to output registers,
-- and scan variable input type modes using config_dta(4 downto 3).
entity AD7328_ACQ is
  PORT ( 
         clk_in       : in  std_logic;
         sys_rst      : in  std_logic;
         en           : in  std_logic;                              -- Enable Acquisition sequence 
         done         : out std_logic;                              -- Acquisition completion flag
         bit_num      : in  unsigned(4 downto 0);
         acq_cs       : out std_logic_vector(1 downto 0);
         acq_sclk     : out std_logic_vector(1 downto 0);
         acq_sdo      : in  std_logic_vector(1 downto 0);
		 ctrlr_reg    : in  std_logic_vector(7 downto 0);
         out1_regA    : out std_logic_vector(31 downto 0);
         out1_regB    : out std_logic_vector(31 downto 0);
         out2_regA    : out std_logic_vector(31 downto 0);
         out2_regB    : out std_logic_vector(31 downto 0)
       );
end AD7328_ACQ;

---- AD7328_ACQ Module Architecture
architecture Behavioral of AD7328_ACQ is

--- Instantiation of the SPI Interface Module
-- AD7328_ACQ uses rd_sdo='1' to place SPI in read-from-ADC mode.
component SPI_INTRFC is
 Port ( 
         clk_in    : in  std_logic;
         sys_rst   : in  std_logic;
         en        : in  std_logic;
         done      : out std_logic;
         cs        : out std_logic_vector(1 downto 0);
         sclk      : out std_logic_vector(1 downto 0); 
         sdi       : out std_logic_vector(1 downto 0);
         sdo       : in  std_logic_vector(1 downto 0);
         rd_sdo    : in  std_logic;    
         bit_num   : in  unsigned(4 downto 0);
         ctrlr_reg : in  std_logic_vector(7 downto 0);           
         adc_in    : in  std_logic_vector(15 downto 0);
         adc1_out  : out std_logic_vector(15 downto 0);
         adc2_out  : out std_logic_vector(15 downto 0)     
      );  
end component;

--- Acquisition State Machine Definition
-- The FSM enables the SPI block to acquire the data and store.
type state_type is (IDLE, ACQ_DTA, CHANL_DTA, FINISH);
signal acq_state: state_type := IDLE;

-- Internal Signals for SPI Interface
signal spi_en        : std_logic;
signal spi_done      : std_logic;
signal spi_dta_out1  : std_logic_vector(15 downto 0);
signal spi_dta_out2  : std_logic_vector(15 downto 0);
signal spi_rd_sdo    : std_logic;
signal dummy_dta_in  : std_logic_vector(15 downto 0);

signal chnl_cnt      : unsigned(3 downto 0) := "0000";        ----- No.of Channels processed based on Input Type mode -----
signal chnl_numA     : std_logic_vector(2 downto 0);          -----      Extracted from ADC outdata (bits 15:13)      -----
signal chnl_numB     : std_logic_vector(2 downto 0);          -----      Extracted from ADC outdata (bits 15:13)      -----

type array_type1 is array (0 to 7) of std_logic_vector(15 downto 0);
signal chnl_dtaA : array_type1;                                 ----- Temporary 13-bit storage for each of 8 ADC channels -----

type array_type2 is array (0 to 7) of std_logic_vector(15 downto 0);
signal chnl_dtaB : array_type2;                                 ----- Temporary 13-bit storage for each of 8 ADC channels -----

begin

--- SPI Interface Instantiation
INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in    => clk_in,
            sys_rst   => sys_rst,
            en        => spi_en,
            done      => spi_done,
            cs        => acq_cs,
            sclk      => acq_sclk,
            sdi       => open,                     -- sdi unused
            sdo       => acq_sdo,
            rd_sdo    => spi_rd_sdo,
            bit_num   => bit_num,
            ctrlr_reg => ctrlr_reg,
            adc_in    => dummy_dta_in,            -- dta_in unused
            adc1_out  => spi_dta_out1,
            adc2_out  => spi_dta_out2
          );
 
 --- Acquired Data Mapping to the Out Registers
DTA_MAP: process(clk_in)
begin
  if rising_edge(clk_in) then
     if acq_state = FINISH then      
        out1_regA(15 downto 0)  <= chnl_dtaA(0);      ----- Channel 0 Data -----  
        out1_regA(31 downto 16) <= chnl_dtaA(2);      ----- Channel 2 Data -----     
        out1_regB(15 downto 0)  <= chnl_dtaA(4);      ----- Channel 4 Data -----      
        out1_regB(31 downto 16) <= chnl_dtaA(6);      ----- Channel 6 Data -----
        out2_regA(15 downto 0)  <= chnl_dtaB(0);        
        out2_regA(31 downto 16) <= chnl_dtaB(2);
        out2_regB(15 downto 0)  <= chnl_dtaB(4);      
        out2_regB(31 downto 16) <= chnl_dtaB(6);
     end if;
  end if;
 end process DTA_MAP;

--- Main Acquisition Process
-- Controls SPI read sequence, channels cycle and completion flag.
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
               acq_state <= ACQ_DTA;
               spi_rd_sdo <= '1';
            elsif en = '0' then
               done <= '0';
               spi_en <= '0';
               spi_rd_sdo <= '0';
            end if;
          
         -- ACQ_DTA: Start SPI read, wait for 16-bit frame  
          when ACQ_DTA =>
            spi_en <= '1';
            if spi_done = '1' then
               chnl_numA <= spi_dta_out1(15 downto 13);    -- Extract Channel ID
               chnl_numB <= spi_dta_out2(15 downto 13);    -- Extract Channel ID
               spi_en <= '0';
               acq_state <= CHANL_DTA;
            end if;
          
         -- CHANL_DTA: Store data in the correct channel slot  
          when CHANL_DTA =>
            chnl_dtaA(to_integer(unsigned(chnl_numA))) <= spi_dta_out1(15 downto 0);
            chnl_dtaB(to_integer(unsigned(chnl_numB))) <= spi_dta_out2(15 downto 0);
            if chnl_cnt < 7 then
               chnl_cnt <= chnl_cnt + 1;
               acq_state <= ACQ_DTA;
            else
               chnl_cnt <= "0000";
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
