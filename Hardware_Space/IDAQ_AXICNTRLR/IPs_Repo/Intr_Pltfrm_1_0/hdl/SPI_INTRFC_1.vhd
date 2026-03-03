---- LIBRARY DECLARATION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

---- ENTITY DECLARATION
-- Generic, Mode-Configurable SPI Interface
-- Three Update Freq modes (~2 MUPS / ~1 MUPS / ~0.5 MUPS)
-- Three Serial Clock modes (~32 MHz / ~16 MHz / ~8 MHz)
-- Frequency Modes are User-Selectable Modes
entity SPI_INTRFC_1 is
  Port ( 
         clk_in     : in  std_logic;
         sys_rst    : in  std_logic;
         en         : in  std_logic;                               -- Enable SPI frame
         done       : out std_logic;                               -- Completion SPI Frame
         cs         : out std_logic_vector(3 downto 0);
         sclk       : out std_logic_vector(3 downto 0); 
         sdi        : out std_logic_vector(3 downto 0);
         sdo        : in  std_logic_vector(3 downto 0);
         strm_on    : in  std_logic;                               -- Enable Streaming Mode (Continous)
         bit_flg    : out std_logic;
         bit_num    : in  unsigned(4 downto 0);
         ctrlr_reg  : in  std_logic_vector(7 downto 0);            -- Only (1 downto 0) are decoded to determine the SPI_INTRFC logic  
         dac1_dta   : in  std_logic_vector(31 downto 0);     
         dac2_dta   : in  std_logic_vector(31 downto 0);
         dac3_dta   : in  std_logic_vector(31 downto 0);
         dac4_dta   : in  std_logic_vector(31 downto 0)
      );  
end SPI_INTRFC_1;

---- SPI_INTRFC_1 Module Architecture
architecture Behavioral of SPI_INTRFC_1 is
 
  -- Delay controller for reset/hold timings
component DLY_CTRLR is
 Port (
         clk_in  : in  std_logic;
         sys_rst : in  std_logic;
         en      : in  std_logic;
         done    : out std_logic;
         dly_tme : in  unsigned(23 downto 0)
       );
end component;

 --- State Machine Holds the active state of the SPI interface controller.
 type states is (IDLE, TOGGLE, DLY, FINISH);
 signal current_state : states := IDLE;
 
 --- Internal working frame related signals
 signal cs_tmp    : std_logic := '1';
 signal sclk_tmp  : std_logic := '0';
 signal srl_cntr  : unsigned(9 downto 0) := (others => '0');               -- Main Frame Counter
 
 --- Internal working Bit Count related signals  
 signal fst_bit      : std_logic := '1';                                   -- First bit of frame
 signal bit_cnt      : unsigned(4 downto 0) := "01111";                    -- Counts down current bit 
 signal cnt_pos      : unsigned(4 downto 0) := "01010";
 signal pos_cntr     : unsigned(4 downto 0) := "00000";                    -- Position counter inside for each bit 
       
 --- Internal User-selectable working signals
 signal frm_lngth  : unsigned(9 downto 0) := "0010000010";                 -- SPI frame length based on mode
 signal bit_pos    : unsigned(3 downto 0) := "0011";                       -- SCLK position where data is output
 signal tgl_lngth  : unsigned(1 downto 0) := "10";                         -- SCLK toggle length based on mode
 
   --- DLY_MODULE Module Internal Signals
 signal dly_en   : std_logic := '0';
 signal dly_done : std_logic := '0';
 signal dly_tme  : unsigned(23 downto 0) := x"000005";
 
begin
 
  -- Delay Controller Instantiation
 DELAY_CTRL: DLY_CTRLR
  Port Map (
             clk_in  => clk_in,
             sys_rst => sys_rst,
             en      => dly_en,
             done    => dly_done,
             dly_tme => dly_tme
           );

  cs          <= cs_tmp & cs_tmp & cs_tmp & cs_tmp;
  sclk        <= (sclk_tmp & sclk_tmp & sclk_tmp & sclk_tmp) when current_state = TOGGLE else "0000";
 
  --- FREQ MODE SELECTION BASED ON ctrlr_reg
  -- Selects SPI timing parameters based on ctrl_reg(1:0) and streaming mode.
  -- Decides SCLK toggle speed, bit toggle positions, and total frame length.
  FREQ_SEL: process(clk_in)
  begin
    if rising_edge(clk_in) then
      if en = '1' and current_state = IDLE then
        case ctrlr_reg(1 downto 0) is
        
          when "01" =>                                         ----- DEFAULT MODE (1 MUPS Update Freq & ~32 MHz Serial Clock Freq) -----
            tgl_lngth <= to_unsigned(2,2);
            cnt_pos   <= to_unsigned(9,5); 
            bit_pos   <= to_unsigned(3,4);                     
            if strm_on = '0' then
              frm_lngth <= to_unsigned(130,10); 
            else
              frm_lngth <= to_unsigned(450,10);
            end if;

          when "10" =>                                          ----- SLOW MODE (0.5 MUPS Update Freq & ~8 MHz Serial Clock Freq) -----
            tgl_lngth <= to_unsigned(3,2);
            cnt_pos   <= to_unsigned(17,5);
            bit_pos   <= to_unsigned(7,4); 
            if strm_on = '0' then
              frm_lngth <= to_unsigned(260,10);
            else
              frm_lngth <= to_unsigned(900,10);
            end if;

          when "11" =>                                          ----- FAST MODE (2 MUPS Update Freq & ~16 MHz Serial Clock Freq) -----
            tgl_lngth <= to_unsigned(1,2);
            cnt_pos   <= to_unsigned(5,5);
            bit_pos   <= to_unsigned(2,4);
            if strm_on = '0' then
              frm_lngth <= to_unsigned(65,10);
            else
              frm_lngth <= to_unsigned(225,10);
            end if;

          when others =>                                        ----- DEFAULT MODE (1 MUPS Update Freq & ~32 MHz Serial Clock Freq) -----
            tgl_lngth <= to_unsigned(2,2);
            cnt_pos   <= to_unsigned(9,5);
            bit_pos   <= to_unsigned(3,4);
            if strm_on = '0' then
              frm_lngth <= to_unsigned(130,10);
            else
              frm_lngth <= to_unsigned(450,10);
            end if;
            
        end case;
      end if;
    end if;
  end process FREQ_SEL;
  
  --- Main FSM handling SPI frame flow:
  SPI_STATE: process(clk_in)
  begin
    if rising_edge(clk_in) then
       if sys_rst = '0' then
          done <= '0';
          cs_tmp <= '1';
          dly_en  <= '0'; 
          dly_tme <= x"000005";
          current_state <= IDLE;
       else
          case current_state is
          
          -- IDLE: Wait for 'en' to start the SPI sequence
            when IDLE =>
              done <= '0';
              if en = '1' then
                 cs_tmp <= '0';
                 current_state <= TOGGLE;
              end if;
          
          -- TOGGLE: Main SCLK Toggling state
            when TOGGLE =>
              if srl_cntr = frm_lngth then
                 cs_tmp <= '1';
                 dly_tme <= x"000005";
                 if strm_on = '0' then
                    current_state <= DLY;
                 else
                    current_state <= FINISH;
                 end if;
              end if;
              
          -- DLY:  Stable CS High Delay
            when DLY =>
              dly_en <= '1';
              if dly_done = '1' and dly_en /= '0' then
                 dly_en <= '0';
                 current_state <= FINISH;
              end if;
          
          -- FINISH: Assert done, wait for deassert of enable  
            when FINISH =>
              done <= '1';
              if en = '0' then                    
                 done <= '0';
                 current_state <= IDLE;
              end if;
          
          --Safety Fallback State
            when others =>
              current_state <= IDLE;
              
          end case;
      end if;
    end if;
  end process SPI_STATE;
  
  --- SCLK Generation using tgl_lngth
  SCLK_PROCS: process(clk_in)
  begin
    if rising_edge(clk_in) then
      
      -- Increments frame counter only during TOGGLE state.
       if current_state = TOGGLE then
          srl_cntr <= srl_cntr + 1;
          sclk_tmp <= srl_cntr(to_integer(tgl_lngth));

     -- Resets counter when not active.
       else
          srl_cntr <= (others => '0');
       end if;
    end if;
  end process SCLK_PROCS;
  
  --- Handles bit timing
  BIT_PROCS: process(clk_in)
  begin
    if rising_edge(clk_in) then
       if sys_rst = '0' then
          fst_bit <= '1';
          bit_flg <= '0';
          bit_cnt  <= "01111";
          pos_cntr <= "00000";
       elsif current_state = TOGGLE then
          if ((fst_bit = '1') and (pos_cntr = cnt_pos)) or ((fst_bit = '0') and (pos_cntr = cnt_pos - 2)) then
           
           -- Special case: Customised accordingly with DAC 
             if bit_cnt = 1 and bit_num = "11111" then
                bit_flg <= '1';
                bit_cnt <= bit_cnt - 1;
             elsif bit_cnt = 0 and bit_num = "11111" then
                bit_cnt <= "10111";
             elsif bit_cnt = 0 and bit_num /= "11111" then
                 bit_cnt <= bit_num;
             else
                bit_cnt <= bit_cnt - 1;
                fst_bit <= '0';
                bit_flg <= '0';
             end if;
             pos_cntr <= "00000";
             
          else
             pos_cntr <= pos_cntr + 1;
          end if;
       else
         bit_flg <= '0';
         fst_bit <= '1';
         bit_cnt <= bit_num;
         pos_cntr <= "00000";
       end if;
    end if;
  end process BIT_PROCS;
 
 --- Drives SDI based bit_pos selected from the mode
  DTA_WRT: process(clk_in)
  begin
    if falling_edge(clk_in) then
       if current_state = TOGGLE then
          if ((fst_bit = '1') and (pos_cntr = bit_pos)) or ((fst_bit = '0') and (pos_cntr = (bit_pos - 2))) then
             sdi(0) <= dac1_dta(to_integer(bit_cnt));
             sdi(1) <= dac2_dta(to_integer(bit_cnt));
             sdi(2) <= dac3_dta(to_integer(bit_cnt));
             sdi(3) <= dac4_dta(to_integer(bit_cnt));
          end if;      
       else
          sdi <= "1111";
       end if;
    end if;
  end process DTA_WRT;

          
end Behavioral;
