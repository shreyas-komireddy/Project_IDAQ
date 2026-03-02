--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  AD3542_CTRLR
--  TOP-LEVEL CONTROLLER FOR AD3542 SPI ADC
--  Handles:
--     ? Initial delay 
--     ? Configuration sequence
--     ? Continuous or single DAC Input Loading
--     ? AXI-driven controller mode selection
--
--  Submodules:
--     1. AD3542_CONFIG  ? Sends 16-bit config frame to ADC
--     2. AD3542_LOAD    ? Performs data loading (2 x 16-bit inputs)
--     3. DLY_CTRLR      ? Generic delay generator (initial wait)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
entity AD3542_CTRLR is
  Port (
         clk_in        : in  std_logic;
         sys_rst       : in  std_logic;
         ad3542_cs     : out std_logic;
         ad3542_sclk   : out std_logic;
         ad3542_sdi    : out std_logic;                        -- SDI used during configuration 
         ad3542_sdo    : in  std_logic;                        -- SDOs used during acquisition
         ad3542_rst    : out std_logic;
         ad3542_ldac   : out std_logic;
         ctrlr_reg     : in  std_logic_vector(7 downto 0);      ---------   AD3542 CONTROLLER BITS written through AXI SLave Register (7 downto 0)  ---------
         led_out       : out std_logic_vector(7 downto 0)
       );
end AD3542_CTRLR;

---- AD3542_CTRLR Module Architecture
architecture Structural of AD3542_CTRLR is

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
--	probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe13 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe15 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--	probe16 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
--);
--END COMPONENT  ;




component AD3542_CONFIG is
 Port ( 
         clk_in         : in  std_logic;
         sys_rst        : in  std_logic;
         en             : in  std_logic;
         done           : out std_logic;
         dac_rst        : out std_logic;
         config_cs      : out std_logic;
         config_sclk    : out std_logic;
         config_sdi     : out std_logic;
         strm_on        : in  std_logic;
         ctrlr_reg      : in  std_logic_vector(7 downto 0);
         config_dta     : in  std_logic_vector(31 downto 0)
       );
end component;

component AD3542_LOAD is
 Port ( 
         clk_in    : in  std_logic;
         sys_rst   : in  std_logic;
         en        : in  std_logic;
         done      : out std_logic;
         dac_ldac  : out std_logic;
         load_cs   : out std_logic;
         load_sclk : out std_logic;
         load_sdi  : out std_logic;
         strm_on   : in  std_logic;
         ctrlr_reg : in  std_logic_vector(7 downto 0);
         ch1_dta   : in  std_logic_vector(15 downto 0);
         ch0_dta   : in  std_logic_vector(15 downto 0)
       );
end component;

component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

-- State Machine Declaration
type state is (IDLE, INITL_DLY, CONFIG, LOAD, DONE);
signal ctrlr_state : state := IDLE;

-- Config Module Internal Signals
signal config_en   : std_logic := '0';
signal config_done : std_logic := '0';
signal dac_rst     : std_logic := '1';
signal config_cs   : std_logic;
signal config_sclk : std_logic;
signal config_sdi  : std_logic;

-- Load Module Internal Signals
signal load_en    : std_logic := '0';
signal load_done  : std_logic := '0';
signal dac_ldac   : std_logic := '1';
signal load_cs    : std_logic;
signal load_sclk  : std_logic;
signal load_sdi   : std_logic;

 --- DLY_MODULE Module Internal Signals
 signal dly_en   : std_logic := '0';
 signal dly_done : std_logic := '0';
 signal dly_tme  : unsigned(23 downto 0) := x"BEBC2A"; 
 
 signal strm_on  : std_logic := '0';
 
 signal slv_reg0 : std_logic_vector(31 downto 0) := x"00000000";           --- AD7384 CONFIG_DTA Configuration DATA written through AXI SLave Register 0 --- 
 signal slv_reg1 : std_logic_vector(31 downto 0) := x"FFFFFFFF";      --- AD7384 CH_1(31 downto 16) & CH_3(15 downto 0) DATA written through AXI SLave Register 1 --- 

-- signal clk_prob  : std_logic;  
 
-- signal dummy_probe : std_logic;

begin


--your_instance_name : ila_0
--PORT MAP (
--	clk => clk_in,



--	probe0(0) => clk_prob, 
--	probe1(0) => config_cs, 
--	probe2(0) => config_sclk, 
--	probe3(0) => config_sdi, 
--	probe4(0) => config_en, 
--	probe5(0) => config_done, 
--	probe6(0) => load_cs, 
--	probe7(0) => load_sclk, 
--	probe8(0) => load_sdi, 
--	probe9(0) => load_en, 
--	probe10(0) => load_done, 
--	probe11(0) => strm_on, 
--	probe12(0) => dac_rst, 
--	probe13(0) => dac_ldac, 
--	probe14(0) => dly_en, 
--	probe15(0) => dly_done,
--	probe16 => ctrlr_reg
--);



-- Config Moduel Instantiation
CONFIG_MODULE: AD3542_CONFIG
  Port Map (
            clk_in        => clk_in,
            sys_rst       => sys_rst,
            en            => config_en,
            done          => config_done,
            dac_rst       => dac_rst,
            config_cs     => config_cs,
            config_sclk   => config_sclk,
            config_sdi    => config_sdi,
            strm_on       => strm_on,
            ctrlr_reg     => ctrlr_reg,
            config_dta    => slv_reg0
          );

LOAD_MODULE: AD3542_LOAD
 Port Map (
            clk_in        => clk_in,
            sys_rst       => sys_rst,
            en            => load_en,
            done          => load_done,
            dac_ldac      => dac_ldac,
            load_cs       => load_cs,
            load_sclk     => load_sclk,
            load_sdi      => load_sdi,
            strm_on       => strm_on,
            ctrlr_reg     => ctrlr_reg,
            ch1_dta       => slv_reg1(31 downto 16),
            ch0_dta       => slv_reg1(15 downto 0)
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
 
 -- SPI MUXING BETWEEN CONFIG + LOAD MODULES
-- Based on FSM state:
--    CONFIG  : AD3542_CONFIG drives CS/SCLK/SDI
--    LOAD    : AD3542_LOAD drives CS/SCLK/SDI          
ad3542_cs    <= config_cs   when ctrlr_state = CONFIG else load_cs;
ad3542_sclk  <= config_sclk when ctrlr_state = CONFIG else load_sclk;
ad3542_sdi   <= config_sdi  when ctrlr_state = CONFIG else load_sdi;
ad3542_rst   <= dac_rst     when ctrlr_state = CONFIG else '1';
ad3542_ldac  <= dac_ldac    when ctrlr_state = LOAD else '1';

config_en    <= '1' when ctrlr_state = CONFIG  else '0';
load_en      <= '1' when ctrlr_state = LOAD else '0';

--CLK_TST: process(clk_in)
--begin
--  if rising_edge(clk_in) then
--    clk_prob <= not clk_prob;
--  end if;
--end process CLK_TST;

--- Main FSM process that handles the AD3542 Sequence
MAIN_PROCESS: process(clk_in)
begin
 if rising_edge(clk_in) then
    if sys_rst = '0' then
       strm_on <= '0';
       dly_en <= '0';
       ctrlr_state <= IDLE;
       dly_tme <= x"BEBC2A";
    else
       case ctrlr_state is
     
        -- IDLE: Immediately enter Initial Delay phase
         when IDLE =>
           strm_on <= '0';
           dly_en <= '0';
           ctrlr_state <= INITL_DLY;
           dly_tme <= x"BEBC2A";
           led_out <= x"00";
     
        -- INITL_DLY: ADC Power-up time Delay 
         when INITL_DLY =>
           dly_en <= '1';
           led_out <= x"11";
           if dly_done = '1' then
              dly_en <= '0';
              ctrlr_state <= CONFIG;
           end if;
     
        -- CONFIG: AD3542 Configuration  
         when CONFIG =>
           led_out <= x"88";
           if config_done = '1' then
              strm_on <= '1';
              ctrlr_state <= LOAD;
           end if;
     
        -- LOAD: AD3542 Loading
         when LOAD =>
           led_out <= x"AA";
           if load_done = '1' then
              ctrlr_state <= DONE;
           end if;
         
        -- DONE: AXI-Controlled Mode Selection  
         when DONE =>
           led_out <= x"55";
           if ctrlr_reg(7 downto 6)    = "01" then        ---- Continous Loading ----
              strm_on <= '1';
              ctrlr_state <= LOAD;
           elsif ctrlr_reg(7 downto 6) = "10" then        ---- Re-configuration ----
              strm_on <= '0';
              ctrlr_state <= CONFIG;
           elsif ctrlr_reg(7 downto 6) = "11" then        ---- Hold-
              ctrlr_state <= DONE;
           end if;
      
        -- Safety Fallback 
         when others =>
           ctrlr_state <= IDLE;
         
     end case;
   end if;
 end if;
end process MAIN_PROCESS;
end Structural;

