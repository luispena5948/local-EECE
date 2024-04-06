library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity amcp_send is
    port (
        adata    : out std_logic_vector(7 downto 0);
        a_en     : out std_logic;
        aready   : out std_logic;
        adatain  : in std_logic_vector(7 downto 0);
        asend    : in std_logic;
        aq2_ack  : in std_logic;
        aclk     : in std_logic;
        arst_n   : in std_logic
    );
end entity amcp_send;

architecture rtl of amcp_send is
	signal	aack: 			std_logic; -- acknowledge pulse from pulse generator
	signal	anxt_data:		std_logic;
	signal	aready_line:	std_logic;
	signal	asend_line:		std_logic;
	signal	a_en_line:		std_logic;
	signal	arst_n_line:	std_logic;
	signal	adata_line:		std_logic_vector(7 downto 0);
	signal	adatain_line:	std_logic_vector(7 downto 0);
	 

    -- Pulse Generator
    component plsgen
        port (
            pulse : out std_logic;
            q     : out std_logic;
            d     : in std_logic;
            clk   : in std_logic;
            rst_n : in std_logic
        );
    end component;

    -- data ready/acknowledge FSM
    component asend_fsm
        port (
            adata    : out std_logic_vector(7 downto 0);
            a_en     : out std_logic;
            aready   : out std_logic;
            adatain  : in std_logic_vector(7 downto 0);
            asend    : in std_logic;
            aq2_ack  : in std_logic;
            aclk     : in std_logic;
            arst_n   : in std_logic;
            aack     : in std_logic
        );
    end component;

    
begin
	
	aready		<=	aready_line;
	--a_en			<=	a_en_line;
	
	asend_line	<=	asend;
	arst_n_line	<= arst_n;
	
	--adata				<=	adata_line;
	adatain_line	<=	adatain;
	
    -- Pulse Generator
    pg1 : entity work.plsgen
        port map (
            pulse => aack,
            q     => open,
            d     => aq2_ack,
            clk   => aclk,
            rst_n => arst_n_line
        );

    -- data ready/acknowledge FSM
    fsm : entity work.asend_fsm
        port map (
            adata    => adata_line,
            a_en     => a_en_line,
            aready   => aready_line,
            adatain  => adatain_line,
            asend    => asend_line,
            aq2_ack  => aq2_ack,
            aclk     => aclk,
            arst_n   => arst_n_line,
            aack     => aack
        );

    -- send next data word
    anxt_data <= (aready_line and asend_line);

    -- toggle-flop controlled by anxt_data
    process (aclk, arst_n_line)
    begin
        if arst_n_line = '0' then
            a_en_line <= '0';
        elsif rising_edge(aclk) then
            if anxt_data = '1' then
                a_en_line <= '1';
            end if;
        end if;
    end process;

    process (aclk, arst_n_line)
    begin
        if arst_n_line = '0' then
            adata_line <= (others => '0');
        elsif rising_edge(aclk) then
            if anxt_data = '1' then
                adata_line <= adatain_line;
            end if;
        end if;
    end process;
end architecture rtl;