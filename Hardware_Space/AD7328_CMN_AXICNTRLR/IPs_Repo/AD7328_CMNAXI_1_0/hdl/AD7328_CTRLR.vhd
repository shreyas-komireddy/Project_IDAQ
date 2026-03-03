--==================================================================================================================================================================================================
--  AD7328_CTRLR
--  TOP-LEVEL CONTROLLER FOR AD7328 SPI ADC
--  Handles:
--     • Initial delay 
--     • Configuration sequence
--     • Continuous or single acquisition
--     • AXI-driven controller mode selection
--
--  Submodules:
--     1. AD7328_CONFIG  - Sends 32-bit config frame to ADC
--     2. AD7328_ACQ     - Performs data acquisition (8 x 13-bit outputs)
--     3. DLY_CTRLR      - Generic delay generator (initial wait)
--=================================================================================================================================================================================================

---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
entity AD7328_CTRLR is
  Port ( 
          clk_in        : in  std_logic;
          sys_rst       : in  std_logic;
          ad7328_cs     : out std_logic_vector(1 downto 0);
          ad7328_sclk   : out std_logic_vector(1 downto 0); 
          ad7328_sdi    : out std_logic_vector(1 downto 0);                        -- SDI used during configuration                           
          ad7328_sdo    : in  std_logic_vector(1 downto 0);                        -- SDO used during acquisition
          ctrlr_reg     : in  std_logic_vector(7 downto 0);     ---------   AD7328 CONTROLLER BITS controlled through Slide switches  ---------
          led_out       : out std_logic_vector(7 downto 0);
          config_dta    : in  std_logic_vector(31 downto 0);
          out1_regA     : out std_logic_vector(31 downto 0);
          out1_regB     : out std_logic_vector(31 downto 0);
          out2_regA     : out std_logic_vector(31 downto 0);
          out2_regB     : out std_logic_vector(31 downto 0)          
       );
end AD7328_CTRLR;


---- AD7328_CTRLR Module Architecture
architecture Structural of AD7328_CTRLR is

--- Instantiation of the AD7328 Config Module
component AD7328_CONFIG is
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
end component;

--- Instantiation of the AD7328 Acquire Module
component AD7328_ACQ is
  PORT ( 
         clk_in       : in  std_logic;
         sys_rst      : in  std_logic;
         en           : in  std_logic;                              -- Enable Acquisition sequence 
         done         : out std_logic;                              -- Acquisition completion flag
         bit_num      : in  unsigned(4 downto 0);
         acq_cs       : out std_logic_vector(1 downto 0);
         acq_sclk     : out std_logic_vector(1 downto 0);
         acq_sdo      : in  std_logic_vector(1 downto 0);
         ctrlr_reg    : in  std_logic_vector(7 downto 0);           -- Only (4 downto 3) are decoded to determine the AD7328_ACQ logic
         config_dta   : in  std_logic_vector(31 downto 0);          -- Only (4 downto 3) are decoded to determine  the AD7328_ACQ logic
         out1_regA    : out std_logic_vector(31 downto 0);
         out1_regB    : out std_logic_vector(31 downto 0);
         out2_regA    : out std_logic_vector(31 downto 0);
         out2_regB    : out std_logic_vector(31 downto 0)
       );
end component;

--- Instantiation of the Delay Controller Module
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)                   -- Delay value
       );
end component;

-- CONFIG control signals
signal config_en   : std_logic := '0';
signal config_done : std_logic;
signal config_cs   : std_logic_vector(1 downto 0);
signal config_sclk : std_logic_vector(1 downto 0);

-- ACQUISITION control signals
signal acq_en      : std_logic := '0';
signal acq_done    : std_logic;
signal acq_cs      : std_logic_vector(1 downto 0);
signal acq_sclk    : std_logic_vector(1 downto 0);

-- Delay control signals
signal dly_en      : std_logic := '0';
signal dly_done    : std_logic;
signal dly_tme     : unsigned(23 downto 0) := x"BEBC2A";             --- 100 ms Initial Delay is loaded ---

signal bit_num     : unsigned(4 downto 0) := "01111";                --- Bit Number "15" (Decrementing) is loaded ---
   
-- State Machine Declaration
type state is (IDLE, INITL_DLY, CONFIG, ACQUIRE, DONE);
signal ctrlr_state : state := IDLE;

begin

CONFIG_MODULE: AD7328_CONFIG
 Port Map (
            clk_in      => clk_in,
            sys_rst     => sys_rst,
            en          => config_en,
            done        => config_done,
            bit_num     => bit_num,
            config_cs   => config_cs,
            config_sclk => config_sclk,
            config_sdi  => ad7328_sdi,
            ctrlr_reg   => ctrlr_reg,
            config_dta  => config_dta   
           );

ACQUIRE_MODULE: AD7328_ACQ
 Port Map (
            clk_in      => clk_in,
            sys_rst     => sys_rst,
            en          => acq_en,
            done        => acq_done,
            bit_num     => bit_num,
            acq_cs      => acq_cs,
            acq_sclk    => acq_sclk,
            acq_sdo     => ad7328_sdo,
            ctrlr_reg   => ctrlr_reg,
            config_dta  => config_dta,
            out1_regA   => out1_regA,
            out1_regB   => out1_regB,
            out2_regA   => out2_regA,
            out2_regB   => out2_regB
          );

DELAY_MODULE: DLY_CTRLR
 Port Map (
            clk_in      => clk_in,
            sys_rst     => sys_rst,
            en          => dly_en,
            done        => dly_done,
            dly_tme     => dly_tme
           );

-- SPI MUXING BETWEEN CONFIG + ACQUIRE MODULES
-- Based on FSM state:
--    CONFIG  ? AD7328_CONFIG drives CS/SCLK
--    ACQUIRE ? AD7328_ACQ drives CS/SCLK          
ad7328_cs    <= config_cs   when ctrlr_state = CONFIG else acq_cs;
ad7328_sclk  <= config_sclk when ctrlr_state = CONFIG else acq_sclk;

config_en    <= '1' when ctrlr_state = CONFIG  else '0';
acq_en       <= '1' when ctrlr_state = ACQUIRE else '0'; 

--- Main FSM process that handles the AD7328 Sequence
MAIN_PROCESS: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        ctrlr_state <= IDLE;
        bit_num <= "01111";
        dly_tme <= x"BEBC2A";
     else
        case ctrlr_state is
     
         -- IDLE: Immediately enter Initial Delay phase
          when IDLE =>
            ctrlr_state <= INITL_DLY;
            dly_tme <= x"000020";
     
         -- INITL_DLY: ADC Power-up time Delay 
          when INITL_DLY =>
            dly_en <= '1';
            if dly_done = '1' then
               dly_en <= '0';
               ctrlr_state <= CONFIG;
               bit_num <= "01111";
            end if;
     
         -- CONFIG: AD7328 Configuration  
          when CONFIG =>
            if config_done = '1' then
               ctrlr_state <= ACQUIRE;
               bit_num <= "01111";
            end if;
     
         -- ACQUIRE: AD7328 Acquisition  
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
