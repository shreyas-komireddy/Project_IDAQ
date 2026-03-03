--==================================================================================================================================================================================================
--  AD7384_CTRLR
--  TOP-LEVEL CONTROLLER FOR AD7384 SPI ADC
--  Handles:
--     • Initial delay 
--     • Configuration sequence
--     • Continuous or single acquisition
--     • AXI-driven controller mode selection
--
--  Submodules:
--     1. AD7384_CONFIG  – Sends 16-bit config frame to ADC
--     2. AD7384_ACQ     – Performs data acquisition (4 x 16-bit outputs)
--     3. DLY_CTRLR      – Generic delay generator (initial wait)
--=================================================================================================================================================================================================

---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
entity AD7384_CTRLR is
  Port (
         clk_in        : in  std_logic;
         sys_rst       : in  std_logic;
         ad7384_cs     : out std_logic;
         ad7384_sclk   : out std_logic;
         ad7384_sdi    : out std_logic;                        -- SDI used during configuration 
         ad7384_sdo_a  : in  std_logic;                        -- SDOs used during acquisition
         ad7384_sdo_b  : in  std_logic;
         ad7384_sdo_c  : in  std_logic;
         ad7384_sdo_d  : in  std_logic;
         ctrlr_reg     : in  std_logic_vector(7 downto 0);      ---------   AD7384 CONTROLLER BITS written through AXI SLave Register 0 (7 downto 0)  ---------
         led_out       : out std_logic_vector(7 downto 0)
       );
end AD7384_CTRLR;

---- AD7384_CTRLR Module Architecture
architecture Structural of AD7384_CTRLR is

-- COMPONENT ila_0

-- PORT (
-- 	clk : IN STD_LOGIC;



-- 	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
-- 	probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
-- 	probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
-- 	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
-- 	probe4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
-- 	probe5 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
-- 	probe6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
-- 	probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
-- );
-- END COMPONENT;

--- Instantiation of the AD7384 Config Module
component AD7384_CONFIG is
 Port (
         clk_in       : in  std_logic;
         sys_rst      : in  std_logic;
         en           : in  std_logic;
         done         : out std_logic;
         bit_num      : in  unsigned(4 downto 0);
         config_cs    : out std_logic;
         config_sclk  : out std_logic;
         config_sdi   : out std_logic;
         ctrlr_reg    : in  std_logic_vector(7 downto 0)
       );
end component;

--- Instantiation of the AD7384 Acquire Module
component AD7384_ACQ is
 Port ( 
         clk_in     : in  std_logic;
         sys_rst    : in  std_logic;
         en         : in  std_logic;
         done       : out std_logic;
         acq_cs     : out std_logic;
         acq_sclk   : out std_logic;
         acq_sdo_a  : in  std_logic;
         acq_sdo_b  : in  std_logic;
         acq_sdo_c  : in  std_logic;
         acq_sdo_d  : in  std_logic;
         bit_num    : in  unsigned(4 downto 0);
         ctrlr_reg  : in  std_logic_vector(7 downto 0);
         out_regA   : out std_logic_vector(31 downto 0);
         out_regB   : out std_logic_vector(31 downto 0)
      );
end component;

--- Instantiation of the Delay Controller Module
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

-- CONFIG control signals
signal config_en   : std_logic := '0';
signal config_done : std_logic ;
signal config_cs   : std_logic;
signal config_sclk : std_logic;

-- ACQUISITION control signals
signal acq_en      : std_logic := '0';
signal acq_done    : std_logic;
signal acq_cs      : std_logic;
signal acq_sclk    : std_logic;

-- Delay control signals
signal dly_en      : std_logic := '0';
signal dly_done    : std_logic;
signal dly_tme     : unsigned(23 downto 0) := x"BEBC20";       --x"BEBC20";             --- 100 ms Initial Delay is loaded ---

signal bit_num     : unsigned(4 downto 0) := "01111";                --- Bit Number "15" (Decrementing) is loaded ---

-- Acquisition data registers (AXI-mapped)
--slv_reg0 & 1 act as data outputs (mapped externally to AXI)
signal slv_reg0    : std_logic_vector(31 downto 0);                  --- AD7384 CH_0(15 downto 0) & CH_1(31 downto 16) DATA read through AXI SLave Register 2 --- 
signal slv_reg1    : std_logic_vector(31 downto 0);                  --- AD7384 CH_2(15 downto 0) & CH_3(31 downto 16) DATA read through AXI SLave Register 3 --- 

-- State Machine Declaration
type state is (IDLE, INITL_DLY, CONFIG, ACQUIRE, DONE);
signal ctrlr_state : state := IDLE;

begin

-- Config Moduel Instantiation
CONFIG_MODULE: AD7384_CONFIG
  Port Map (
             clk_in       => clk_in,
             sys_rst      => sys_rst,
             en           => config_en,
             done         => config_done,
             bit_num      => bit_num,
             config_cs    => config_cs,
             config_sclk  => config_sclk,
             config_sdi   => ad7384_sdi,
             ctrlr_reg    => ctrlr_reg
           );
           
-- Acquire Module Instantiation
ACQUIRE_MODULE: AD7384_ACQ
 Port Map (
            clk_in      => clk_in,
            sys_rst     => sys_rst,
            en          => acq_en,
            done        => acq_done,
            bit_num     => bit_num,
            acq_cs      => acq_cs,
            acq_sclk    => acq_sclk,
            acq_sdo_a   => ad7384_sdo_a,
            acq_sdo_b   => ad7384_sdo_b,
            acq_sdo_c   => ad7384_sdo_c,
            acq_sdo_d   => ad7384_sdo_d,
            ctrlr_reg   => ctrlr_reg,
            out_regA    => slv_reg0,
            out_regB    => slv_reg1
          );

-- Delay Controller Instantiation
DELAY_MODULE: DLY_CTRLR
 Port Map (
            clk_in      => clk_in,
            sys_rst     => sys_rst,
            en          => dly_en,
            done        => dly_done,
            dly_tme     => dly_tme
           );

-- ILA_Analyser : ila_0
-- PORT MAP (
-- 	clk => clk_in,



-- 	probe0(0) => ad7384_sdo_b, 
-- 	probe1(0) => acq_cs, 
-- 	probe2(0) => acq_sclk, 
-- 	probe3(0) => ad7384_sdo_a, 
-- 	probe4 => slv_reg0(15 downto 0), 
-- 	probe5 => slv_reg0(31 downto 16), 
-- 	probe6 => slv_reg1(15 downto 0),
-- 	probe7 => slv_reg1(31 downto 16)
-- );
           

-- SPI MUXING BETWEEN CONFIG + ACQUIRE MODULES
-- Based on FSM state:
--    CONFIG  : AD7384_CONFIG drives CS/SCLK
--    ACQUIRE : AD7384_ACQ drives CS/SCLK          
ad7384_cs    <= config_cs   when ctrlr_state = CONFIG else acq_cs;
ad7384_sclk  <= config_sclk when ctrlr_state = CONFIG else acq_sclk;

config_en    <= '1' when ctrlr_state = CONFIG  else '0';
acq_en       <= '1' when ctrlr_state = ACQUIRE else '0';

LED_MAP: process(clk_in)
begin
 if rising_edge(clk_in) then
    if sys_rst = '0' then
       led_out <= x"00";
    else
       case ctrlr_reg(2 downto 0) is
         when "000" =>
           led_out <= slv_reg0(7 downto 0);
         when "001" =>
           led_out <= slv_reg0(15 downto 8);
         when "010" =>
           led_out <= slv_reg0(23 downto 16);
         when "011" =>
           led_out <= slv_reg0(31 downto 24);
         when "100" =>
           led_out <= slv_reg1(7 downto 0);
         when "101" =>
           led_out <= slv_reg1(15 downto 8);
         when "110" =>
           led_out <= slv_reg1(23 downto 16);
         when "111" =>
           led_out <= slv_reg1(31 downto 24);
         when others =>
           led_out <= slv_reg0(7 downto 0);
       end case;
     end if;
end if;
end process LED_MAP;


--- Main FSM process that handles the AD7384 Sequence
MAIN_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        dly_en <= '0';
        bit_num <= "01111";
        dly_tme <= x"BEBC20";
        ctrlr_state <= IDLE;
     else
        case ctrlr_state is
     
          -- IDLE: Immediately enter Initial Delay phase
           when IDLE =>
             dly_en <= '0';
             ctrlr_state <= INITL_DLY;
             dly_tme <= x"BEBC20";
     
          -- INITL_DLY: ADC Power-up time Delay 
           when INITL_DLY =>
             dly_en <= '1';
             if dly_done = '1' then
                dly_en <= '0';
                ctrlr_state <= CONFIG;
                bit_num <= "01111";
             end if;
     
         -- CONFIG: AD7384 Configuration  
           when CONFIG =>
             if config_done = '1' then
                ctrlr_state <= ACQUIRE;
                bit_num <= "01111";
             end if;
     
         -- ACQUIRE: AD7384 Acquisition  
          when ACQUIRE =>
            if acq_done = '1' then
               ctrlr_state <= DONE;
            end if;
         
         -- DONE: AXI-Controlled Mode Selection  
          when DONE =>
            if ctrlr_reg(7 downto 6)    = "01" then        ---- Continous Acquisition ----
               ctrlr_state <= ACQUIRE;
            elsif ctrlr_reg(7 downto 6) = "10" then        ---- Re-configuration ----
               ctrlr_state <= CONFIG;
            elsif ctrlr_reg(7 downto 6) = "11" then        ---- Hold-
               ctrlr_state <= DONE;
            end if;
            
         -- Safety Fallback State
          when others =>
            ctrlr_state <= IDLE;
         
      end case;
    end if;
 end if;
end process;

end Structural;
