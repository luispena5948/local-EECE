library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity asend_fsm is
	port (
		aready	: out std_logic; 	-- ready to send next data
		asend		: in std_logic;	-- send adata
		aack		: in std_logic;	-- acknowledge receipt of adata
		aclk		: in std_logic;
		arst_n	: in std_logic
	);
end entity asend_fsm;

architecture RTL of asend_fsm is
	type state_t is (READY, BUSY);
	signal state, next_state : state_t;
begin
	-- State register
	process (aclk, arst_n)
	begin
		if (arst_n = '0') then
			state <= READY;
		elsif (rising_edge(aclk)) then
			state <= next_state;
		end if;
	end process;

	-- Next state logic
	process (state, asend, aack)
	begin
		case state is
			when READY =>
				if (asend = '1') then
					next_state <= BUSY;
				else
					next_state <= READY;
				end if;
			
			when BUSY =>
				if (aack = '1') then
					next_state <= READY;
				else
					next_state <= BUSY;
				end if;
		end case;
	end process;

	-- Output assignment
	aready <= '1' when state = READY else '0';
end architecture RTL;