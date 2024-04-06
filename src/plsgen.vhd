-- Pulse Generator
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity plsgen is
	port (
		pulse	: out std_logic;
		q		: out std_logic;
		d		: in	std_logic;
		clk	: in	std_logic;
		rst_n	: in	std_logic
	);
end entity plsgen;

architecture rtl of plsgen is
begin
	process(clk, rst_n)
		variable q_reg : std_logic;
	begin
		if rst_n = '0' then
			q_reg := '0';
		elsif rising_edge(clk) then
			q_reg := d;
		end if;
		
		q		<= q_reg;
		pulse	<= q_reg xor d;
	end process;
end architecture rtl;