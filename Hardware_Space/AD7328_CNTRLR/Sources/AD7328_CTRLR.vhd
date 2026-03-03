--==================================================================================================================================================================================================
--  AD7328_CTRLR
--  TOP-LEVEL CONTROLLER FOR AD7328 SPI ADC
--  Handles:
--     ? Initial delay 
--     ? Configuration sequence
--     ? Continuous or single acquisition
--     ? AXI-driven controller mode selection
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
          ad7328_cs     : out std_logic;
          ad7328_sclk   : out std_logic; 
          ad7328_sdi    : out std_logic;                        -- SDI used during configuration                           
          ad7328_sdo    : in  std_logic;                        -- SDO used during acquisition
          ctrlr_reg     : in  std_logic_vector(7 downto 0);     ---------   AD7328 CONTROLLER BITS written through AXI SLave Register 0 (7 downto 0)  ---------
          led_out       : out std_logic_vector(7 downto 0)
       );
end AD7328_CTRLR;


---- AD7328_CTRLR Module Architecture
architecture Structural of AD7328_CTRLR is

--COMPONENT ila_0

--PORT (
--	clk : IN STD_LOGIC;



--	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--	probe7 : IN STD_LOGIC_VECTOR(12 DOWNTO 0)
--);
--END COMPONENT  ;

--- Instantiation of the AD7328 Config Module
component AD7328_CONFIG is
 Port ( 
         clk_in        : in  std_logic;
         sys_rst       : in  std_logic;
         en            : in  std_logic;
         done          : out std_logic;
         bit_num       : in  unsigned(4 downto 0);
         config_cs     : out std_logic;
         config_sclk   : out std_logic;
         config_sdi    : out std_logic;
         ctrlr_reg     : in  std_logic_vector(7 downto 0);
         config_dta    : in  std_logic_vector(31 downto 0) 
      );
end component;

--- Instantiation of the AD7328 Acquire Module
component AD7328_ACQ is
  Port ( 
         clk_in     : in  std_logic;
         sys_rst    : in  std_logic;
         en         : in  std_logic;
         done       : out std_logic;
         bit_num    : in  unsigned(4 downto 0);
         acq_cs     : out std_logic;
         acq_sclk   : out std_logic;
         acq_sdo    : in  std_logic;
         ctrlr_reg  : in  std_logic_vector(7 downto 0);           
         config_dta : in  std_logic_vector(31 downto 0);                
         out_regA   : out std_logic_vector(31 downto 0);       -- CH 0/1 data
         out_regB   : out std_logic_vector(31 downto 0);       -- CH 2/3 data
         out_regC   : out std_logic_vector(31 downto 0);       -- CH 4/5 data
         out_regD   : out std_logic_vector(31 downto 0);       -- CH 6/7 data
         tst_reg    : out std_logic_vector(15 downto 0)    
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
signal dly_tme     : unsigned(23 downto 0) := x"BEBC2A";             --- 100 ms Initial Delay is loaded ---

signal bit_num     : unsigned(4 downto 0) := "01111";                --- Bit Number "15" (Decrementing) is loaded ---
   
signal slv_reg1    : std_logic_vector(31 downto 0) := x"5555FF11";   --------- AD7328 CONFIGURATION DATA written through AXI SLave Register 1 ---------

-- Acquisition data registers (AXI-mapped)
--slv_reg2..5 act as data outputs (mapped externally to AXI)
signal slv_reg2    : std_logic_vector(31 downto 0);                  --- AD7328 CH_0(15 downto 0) & CH_1(31 downto 16) DATA read through AXI SLave Register 2 --- 
signal slv_reg3    : std_logic_vector(31 downto 0);                  --- AD7328 CH_2(15 downto 0) & CH_3(31 downto 16) DATA read through AXI SLave Register 3 --- 
signal slv_reg4    : std_logic_vector(31 downto 0);                  --- AD7328 CH_4(15 downto 0) & CH_5(31 downto 16) DATA read through AXI SLave Register 4 --- 
signal slv_reg5    : std_logic_vector(31 downto 0);                  --- AD7328 CH_6(15 downto 0) & CH_7(31 downto 16) DATA read through AXI SLave Register 5 --- 

-- State Machine Declaration
type state is (IDLE, INITL_DLY, CONFIG, ACQUIRE, DONE);
signal ctrlr_state : state := IDLE;

signal led_tmp : std_logic_vector(15 downto 0);

begin

--your_instance_name : ila_0
--PORT MAP (
--	clk => clk_in,



--	probe0(0) => config_cs, 
--	probe1(0) => config_sclk, 
--	probe2(0) => acq_cs, 
--	probe3(0) => acq_sclk, 
--	probe4(0) => ad7328_sdo, 
--	probe5(0) => acq_en, 
--	probe6(0) => acq_done,
--	probe7 => slv_reg2(12 downto 0)
--);

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
            config_dta  => slv_reg1   
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
            config_dta  => slv_reg1,
            out_regA    => slv_reg2,
            out_regB    => slv_reg3,
            out_regC    => slv_reg4,
            out_regD    => slv_reg5,
            tst_reg     => led_tmp
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

LED_MAP: process(clk_in)
begin
  if rising_edge(clk_in) then
     if sys_rst = '0' then
        led_out <= x"00";
     else
        case ctrlr_reg(2 downto 0) is
          when "000" =>
            led_out <= slv_reg2(15 downto 13) & slv_reg2(12 downto 8);
            --led_out <= slv_reg2(15 downto 13)  & slv_reg2(11 downto 7);                -- ch0
          when "001" =>
             led_out <= slv_reg2(7 downto 0);
             --led_out <= slv_reg2(31 downto 29) & slv_reg2(27 downto 23);               -- ch1
          when "010" =>
             led_out <= slv_reg3(11 downto 4);
             --led_out <= slv_reg3(15 downto 13)  & slv_reg3(11 downto 7);               -- ch2
          when "011" =>
            led_out <= slv_reg3(27 downto 20);
            --led_out <= slv_reg3(31 downto 29) & slv_reg3(27 downto 23);                -- ch3
          when "100" =>
            led_out <= slv_reg4(11 downto 4);
            --led_out <= slv_reg4(15 downto 13)  & slv_reg4(11 downto 7);                -- ch4
          when "101" => 
            led_out <= slv_reg4(27 downto 20);
            --led_out <= slv_reg4(31 downto 29) & slv_reg4(27 downto 23);                -- ch5
          when "110" =>
            led_out <= slv_reg5(11 downto 4);
            --led_out <= slv_reg5(15 downto 13)  & slv_reg5(11 downto 7);                -- ch6
          when "111" => 
            led_out <= slv_reg5(27 downto 20);
            --led_out <= slv_reg5(31 downto 29) & slv_reg5(27 downto 23);                -- ch7
          when others =>
            led_out <= slv_reg2(15 downto 13)  & slv_reg2(11 downto 7); 
        end case;
     end if;
 end if;
end process LED_MAP;

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
