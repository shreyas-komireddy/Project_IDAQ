---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- Sends 4 configuration frames to the SPI interface
-- Uses the SPI_INTRFC module to perform serial transfers.
entity AD7328_CONFIG is
  Port ( 
         clk_in        : in  std_logic;
         sys_rst       : in  std_logic;
         en            : in  std_logic;                        -- Enable Configuartion sequence                     
         done          : out std_logic;                        -- Sequence completion flag
         bit_num       : in  unsigned(4 downto 0);
         config_cs     : out std_logic_vector(1 downto 0);
         config_sclk   : out std_logic_vector(1 downto 0);
         config_sdi    : out std_logic_vector(1 downto 0);                        
         ctrlr_reg     : in  std_logic_vector(7 downto 0);     -- Not used for this module
         config_dta    : in  std_logic_vector(31 downto 0)     -- All configuration data frames
      );
end AD7328_CONFIG;

---- AD7328_CONFIG Module Architecture
architecture Behavioral of AD7328_CONFIG is


--- Instantiation of the SPI Interface Module
-- Used to shift out 16-bit command words to the AD7328.
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

--- State Machine Controls Configuration Sequence
-- The FSM enables the SPI block and loads one command per state.
 type state is (IDLE, WRT_RANGE_REG1, WRT_RANGE_REG2, WRT_SEQ_REG, WRT_ADCTRL_REG, FINISH);
 signal config_state : state := IDLE;
 
 
-- Signals Connected to the SPI Interface
 signal spi_en        : std_logic;
 signal spi_done      : std_logic;
 signal spi_dta_in    : std_logic_vector(15 downto 0); 
 signal dummy_sdo     : std_logic_vector(1 downto 0);
 signal dummy_rd_sdo  : std_logic;

begin

-- SPI Interface Instantiation
INTRFC_CTRL: SPI_INTRFC
 Port Map (
            clk_in    => clk_in,
            sys_rst   => sys_rst,
            en        => spi_en,
            done      => spi_done,
            cs        => config_cs,
            sclk      => config_sclk,
            sdi       => config_sdi,
            sdo       => dummy_sdo,         -- sdo is unused
            rd_sdo    => dummy_rd_sdo,      -- rd_sdo is unused
            bit_num   => bit_num,
            ctrlr_reg => ctrlr_reg,
            adc_in    => spi_dta_in,
            adc1_out  => open,
            adc2_out  => open               
          );

--- Main Configuration State Machine
-- Loads each register word and triggers the SPI interface
CONFIG_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        spi_dta_in <= "000" & config_dta(7 downto 0) & "00000";
        spi_en <= '0';
        done <= '0';
        config_state <= IDLE;
     else
        case config_state is
     
         -- IDLE: Wait for 'en' to start the configuration sequence
          when IDLE =>
            if en = '1' then
               config_state <= WRT_RANGE_REG1;
               spi_dta_in <= "101" & config_dta(31 downto 24) & "00000";
            elsif en = '0'  then 
               done <= '0';
               spi_en <= '0';
               spi_dta_in <= "000" & config_dta(7 downto 0) & "00000";
            end if;
      
         -- WRT_RANGE_REG1: Loads the RANGE_REG1 [config_dta (31 downto 24)]
          when WRT_RANGE_REG1 =>
            spi_en <= '1';
            if spi_done = '1' then
               spi_en <= '0';
               config_state <= WRT_RANGE_REG2;
               spi_dta_in <= "110" & config_dta(23 downto 16) & "00000";
            end if;
     
         -- WRT_RANGE_REG2: Loads the RANGE_REG3 [config_dta (23 downto 16)]s
          when WRT_RANGE_REG2 =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_SEQ_REG;
               spi_dta_in <= "111" & config_dta(15 downto 8) & "00000";
            end if;
       
         -- WRT_SEQ_REG: Loads the SEQ_REG [config_dta(15 downto 8)] 
          when WRT_SEQ_REG =>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= WRT_ADCTRL_REG;
               spi_dta_in <= "100" & config_dta(7 downto 3) & "0011" & config_dta(2 downto 0) & '0';
            end if;
         
         -- WRT_ADCTRL_REG: Loads the CTRL_REG [config_dta(7 downto 3)]
          when WRT_ADCTRL_REG=>
            spi_en <= '1';
            if spi_done = '1' and spi_en /= '0' then
               spi_en <= '0';
               config_state <= FINISH;
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
