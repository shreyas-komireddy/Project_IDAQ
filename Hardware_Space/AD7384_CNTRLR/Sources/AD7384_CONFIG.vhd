---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
--- Purpose:
--   Handles device-level configuration of the AD7384 ADC.
--   Uses an SPI controller to write configuration words and a
--   delay controller to manage timing gaps after HRD_RST.
entity AD7384_CONFIG is
  Port (
         clk_in       : in  std_logic;
         sys_rst      : in  std_logic;
         en           : in  std_logic;                           -- Enable Configuartion sequence 
         done         : out std_logic;                           -- Sequence completion flag
         bit_num      : in  unsigned(4 downto 0);
         config_cs    : out std_logic;
         config_sclk  : out std_logic;
         config_sdi   : out std_logic;                            
         ctrlr_reg    : in  std_logic_vector(7 downto 0)          -- Not used for this module
       );
end AD7384_CONFIG;

---- AD7384_CONFIG Module Architecture
architecture Behavioral of AD7384_CONFIG is

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

--- Instantiation of the Delay Controller Modules
-- Provides a programmable wait time after Hard Reset
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

-- Signals Connected to the SPI Interface
signal spi_en         : std_logic;
signal spi_done       : std_logic;
signal dummy_sdo_a    : std_logic;
signal dummy_sdo_b    : std_logic;
signal dummy_sdo_c    : std_logic;
signal dummy_sdo_d    : std_logic;
signal dummy_rd_sdo   : std_logic;
signal spi_dta_in     : std_logic_vector(15 downto 0);

-- Signals Connected to the Delay Controller
signal dly_en         : std_logic;
signal dly_done       : std_logic;
signal dly_tme        : unsigned(23 downto 0) := x"00007F";

signal prev_ctrlr_reg : std_logic_vector(7 downto 0);

--- State Machine Controls Configuration Sequence
-- The FSM enables the HRD_RST through SPI block and loads one command per state.
type state is (IDLE, HRD_RST, HOLD, WRT_CONFIG_A, WRT_CONFIG_B, FINISH);
signal config_state : state := IDLE;

begin

-- SPI Interface Instantiation
 INTRFC_CTRL: SPI_INTRFC
  Port Map (
             clk_in     => clk_in,
             sys_rst    => sys_rst,
             en         => spi_en,
             done       => spi_done,
             cs         => config_cs,
             sclk       => config_sclk,
             sdi        => config_sdi,
             sdo_a      => dummy_sdo_a,
             sdo_b      => dummy_sdo_b,
             sdo_c      => dummy_sdo_c,
             sdo_d      => dummy_sdo_d,
             rd_sdo     => dummy_rd_sdo,
             bit_num    => bit_num,
             ctrlr_reg  => ctrlr_reg,
             dta_in     => spi_dta_in,
             spi_outA  => open,
             spi_outB  => open,
             spi_outC  => open,
             spi_outD  => open
           );

-- Delay Controller Instantiation
 DELAY_CTRL: DLY_CTRLR
  Port Map (
             clk_in  => clk_in,
             sys_rst => sys_rst,
             en      => dly_en,
             done    => dly_done,
             dly_tme => dly_tme
           );
 
 --- Main Configuration State Machine
-- Loads each register word and triggers the SPI interface
CONFIG_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        spi_dta_in <= x"0000";
        dly_tme <= x"00007F";
        spi_en <= '0';
        dly_en <= '0';
        done <= '0';     
     else
        case config_state is
     
         -- IDLE: Wait for 'en' to start the configuration sequence 
          when IDLE =>
            if en = '1' then
               config_state <= HRD_RST;
               spi_dta_in  <= x"A2FF";
            elsif en = '0' then 
               done <= '0';
               spi_en <= '0';
            end if;
         
         -- HRD_RST: Issue Hard reset command through SPI  
          when HRD_RST =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= HOLD;
               dly_tme <= x"00007F";
            end if;
         
         -- HOLD: Wait for delay timer to expire 
          when HOLD =>
            dly_en <= '1';
            if dly_done = '1' then
               dly_en <= '0';
               config_state <= WRT_CONFIG_A;
               spi_dta_in  <= x"92C6";
            end if;
         
         -- WRT_CONFIG_A: First configuration word write   
          when WRT_CONFIG_A =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_CONFIG_B;
               spi_dta_in <= x"A200";
            end if;
         
         -- WRT_CONFIG_B: Second and final config word write      
          when WRT_CONFIG_B => 
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= FINISH;
               done <= '1';
            end if;
         
         -- FINISH: Assert done, wait for deassert of enable    
          when FINISH =>
            done <= '1';
            if en = '0' then
               done <= '0';
               config_state <= IDLE;
            end if;
       
         -- Safety Fallback State
          when others =>
            config_state <= IDLE;
       end case;
     end if; 
  end if; 
 end process;
end Behavioral;
