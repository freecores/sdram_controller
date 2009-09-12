----------------------------------------------------------------------------------
-- Company: OPL Aerospatiale AG
-- Engineer: Owen Lynn <lynn0p@hotmail.com>
-- 
-- Create Date:    23:22:19 07/27/2009 
-- Design Name: 
-- Module Name:    scratch - impl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Testbench for the DDR SDRAM controller. Sends a write command, sends a read 
--  and outputs to the led on the Spartan3e Starter Board
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--  Copyright (c) 2009 Owen Lynn <lynn0p@hotmail.com>
--  Released under the GNU Lesser General Public License, Version 3
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library UNISIM;
use UNISIM.VComponents.all;


entity scratch is
	port(         clk : in  std_logic; 
	             clke : in  std_logic;
	              rst : in  std_logic;
                 led : out std_logic_vector( 7 downto 0 );
					  
			-- SDRAM pins out
			  dram_clkp   : out   std_logic;
			  dram_clkn   : out   std_logic;
			  dram_clke   : out   std_logic;
			  dram_cs     : out   std_logic;
			  dram_cmd    : out   std_logic_vector(2 downto 0);
			  dram_bank   : out   std_logic_vector(1 downto 0);
			  dram_addr   : out   std_logic_vector(12 downto 0);
			  dram_dm     : out   std_logic_vector(1 downto 0);
			  dram_dqs    : inout std_logic_vector(1 downto 0);
			  dram_dq     : inout std_logic_vector(15 downto 0);

			-- debug signals
			  debug_reg   : out std_logic_vector(7 downto 0)
			  );
end scratch;

architecture impl of scratch is

	type DRAM_DRIVER_STATES is ( STATE0, STATE1, STATE2, STATE3, STATE4, STATE5 );
	signal dram_driver_state : DRAM_DRIVER_STATES := STATE0;

	signal clk_bufd  : std_logic;
	signal clk133mhz : std_logic;
	signal dcm_locked : std_logic;
	
	signal op      : std_logic_vector(1 downto 0);
	signal addr    : std_logic_vector(25 downto 0);
	signal op_ack  : std_logic;
	signal busy_n  : std_logic;
	signal data_o  : std_logic_vector(7 downto 0);
	signal data_i  : std_logic_vector(7 downto 0);
	signal debug   : std_logic_vector(7 downto 0);
	
	signal reg0 : std_logic_vector(7 downto 0) := x"55";
	
begin

	BUFG_CLK: BUFG
	port map(
		O => clk_bufd,
		I => clk
	);
	
	SDRAM: entity work.sdram_controller 
	port map(
		clk50mhz => clk_bufd,
		en => '1',
	   reset => rst,
	   op => op,
	   addr => addr,
	   op_ack => op_ack,
	   busy_n => busy_n,
	   data_o => led,
	   data_i => data_i,
	             
		dram_clkp => dram_clkp,
		dram_clkn => dram_clkn,
		dram_clke => dram_clke,
		dram_cs => dram_cs,
		dram_cmd => dram_cmd,
		dram_bank => dram_bank,
		dram_addr => dram_addr,
		dram_dm => dram_dm,
		dram_dqs => dram_dqs,
		dram_dq => dram_dq,
		
		debug_reg => debug
	);
	
	debug_reg <= debug;
	
	process(clk_bufd, clke)
	begin
		if (clke = '0') then
			dram_driver_state <= STATE0;
		elsif (rising_edge(clk_bufd)) then
			case dram_driver_state is
				when STATE0 =>
					if (busy_n = '1') then
						dram_driver_state <= STATE1;
					end if;
					
				when STATE1 =>
					addr <= "01000000000000000000000111";
					data_i <= "10101010";
					op <= "10";
					if (op_ack = '1') then
						dram_driver_state <= STATE2;
					end if;
					
				when STATE2 =>
					op <= "00";
					if (busy_n = '1') then
						dram_driver_state <= STATE3;
					end if;
					
				when STATE3 =>
					addr <= "01000000000000000000000111";
					op <= "01";
					if (op_ack = '1') then
						dram_driver_state <= STATE4;
					end if;
					
				when STATE4 =>
					op <= "00";
					if (busy_n = '1') then
						dram_driver_state <= STATE5;
					end if;
					
				when STATE5 =>
					dram_driver_state <= STATE5;					
			end case;
		end if;
	end process;


end impl;
