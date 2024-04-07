library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity asend_fsm is
    port (
        aready : out std_logic;  -- ready to send next data
        asend : in std_logic;    -- send adata
        aack : in std_logic;     -- acknowledge receipt of adata
        aclk : in std_logic;
        arst_n : in std_logic
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity back_fsm is
    port (
        bvalid : out std_logic;  -- data valid / ready to load
        bload : in std_logic;    -- load data / send acknowledge
        b_en : in std_logic;     -- enable receipt of adata
        bclk : in std_logic;
        brst_n : in std_logic
    );
end entity back_fsm;

architecture RTL of back_fsm is
    type state_t is (READY, WAIT);
    signal state, next_state : state_t;
begin
    -- State register
    process (bclk, brst_n)
    begin
        if (brst_n = '0') then
            state <= WAIT;
        elsif (rising_edge(bclk)) then
            state <= next_state;
        end if;
    end process;

    -- Next state logic
    process (state, bload, b_en)
    begin
        case state is
            when READY =>
                if (bload = '1') then
                    next_state <= WAIT;
                else
                    next_state <= READY;
                end if;
            when WAIT =>
                if (b_en = '1') then
                    next_state <= READY;
                else
                    next_state <= WAIT;
                end if;
        end case;
    end process;

    -- Output assignment
    bvalid <= '1' when state = READY else '0';
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmcp_recv is
    port (
        bdata:	out	std_logic_vector(7 downto 0);
        bvalid:	out	std_logic;						-- bdata valid
        b_ack:	out	std_logic;						-- acknowledge signal
        adata:	in	std_logic_vector(7 downto 0);	-- unsynchronized adata
        bload:	in	std_logic;						-- load data and acknowledge receipt
        bq2_en:	in	std_logic;						-- synchronized enable input
        bclk:	in	std_logic;
        brst_n:	in	std_logic
    );
end entity bmcp_recv;

architecture RTL of bmcp_recv is
    signal b_en : std_logic;  -- enable pulse from pulse generator
begin
    -- Pulse Generator
    pg1 : entity work.plsgen
        port map (
            pulse => b_en,
            q => open,
            d => bq2_en,
            clk => bclk,
            rst_n => brst_n
        );

    -- Data ready/acknowledge FSM
    fsm : entity work.back_fsm
        port map (
            bvalid => bvalid,
            bload => bload,
            b_en => b_en,
            bclk => bclk,
            brst_n => brst_n
        );

    -- Load next data word
    bload_data <= bvalid and bload;

    -- Toggle-flop controlled by bload_data
    process (bclk, brst_n)
    begin
        if (brst_n = '0') then
            b_ack <= '0';
        elsif (rising_edge(bclk)) then
            if (bload_data = '1') then
                b_ack <= not b_ack;
            end if;
        end if;
    end process;

    process (bclk, brst_n)
    begin
        if (brst_n = '0') then
            bdata <= (others => '0');
        elsif (rising_edge(bclk)) then
            if (bload_data = '1') then
                bdata <= adata;
            end if;
        end if;
    end process;
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcp_blk is
    generic (
        dat_t : type := std_logic_vector(7 downto 0)
    );
    port (
        aready : out std_logic;   -- ready to receive next data
        adatain : in dat_t;
        asend : in std_logic;
        aclk : in std_logic;
        arst_n : in std_logic;
        bdata : out dat_t;
        bvalid : out std_logic;   -- bdata valid (ready)
        bload : in std_logic;
        bclk : in std_logic;
        brst_n : in std_logic
    );
end entity mcp_blk;

architecture RTL of mcp_blk is
    signal adata : dat_t;  -- internal data bus
    signal b_ack : std_logic;  -- acknowledge enable signal
    signal a_en : std_logic;   -- control enable signal
    signal bq2_en : std_logic; -- control - sync output
    signal aq2_ack : std_logic;  -- feedback - sync output
begin
    async : entity work.sync2
        port map (
            q => aq2_ack,
            d => b_ack,
            clk => aclk,
            rst_n => arst_n
        );

    bsync : entity work.sync2
        port map (
            q => bq2_en,
            d => a_en,
            clk => bclk,
            rst_n => brst_n
        );

    alogic : entity work.amcp_send
        port map (
            adata => adata,
            a_en => a_en,
            aready => aready,
            adatain => adatain,
            asend => asend,
            aq2_ack => aq2_ack,
            aclk => aclk,
            arst_n => arst_n
        );

    blogic : entity work.bmcp_recv
        port map (
            bdata => bdata,
            bvalid => bvalid,
            b_ack => b_ack,
            adata => adata,
            bload => bload,
            bq2_en => bq2_en,
            bclk => bclk,
            brst_n => brst_n
        );
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wctl is
    port (
        wrdy : out std_logic;
        wptr : out std_logic;
        we : out std_logic;
        wput : in std_logic;
        wq2_rptr : in std_logic;
        wclk : in std_logic;
        wrst_n : in std_logic
    );
end entity wctl;

architecture RTL of wctl is
begin
    we <= wrdy and wput;
    wrdy <= not (wq2_rptr xor wptr);

    process (wclk, wrst_n)
    begin
        if (wrst_n = '0') then
            wptr <= '0';
        elsif (rising_edge(wclk)) then
            wptr <= wptr xor we;
        end if;
    end process;
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cdc_syncfifo is
    generic (
        dat_t : type := std_logic_vector(7 downto 0)
    );
    port (
        -- Write clk interface
        wdata : in dat_t;
        wrdy : out std_logic;
        wput : in std_logic;
        wclk : in std_logic;
        wrst_n : in std_logic;
        -- Read clk interface
        rdata : out dat_t;
        rrdy : out std_logic;
        rget : in std_logic;
        rclk : in std_logic;
        rrst_n : in std_logic
    );
end entity cdc_syncfifo;

architecture RTL of cdc_syncfifo is
    signal wptr, we, wq2_rptr : std_logic;
    signal rptr, rq2_wptr : std_logic;
begin
    wctl_inst : entity work.wctl
        port map (
            wrdy => wrdy,
            wptr => wptr,
            we => we,
            wput => wput,
            wq2_rptr => wq2_rptr,
            wclk => wclk,
            wrst_n => wrst_n
        );

    rctl_inst : entity work.rctl
        port map (
            rrdy => rrdy,
            rptr => rptr,
            rget => rget,
            rq2_wptr => rq2_wptr,
            rclk => rclk,
            rrst_n => rrst_n
        );

    w2r_sync : entity work.sync2
        port map (
            q => rq2_wptr,
            d => wptr,
            clk => rclk,
            rst_n => rrst_n
        );

    r2w_sync : entity work.sync2
        port map (
            q => wq2_rptr,
            d => rptr,
            clk => wclk,
            rst_n => wrst_n
        );

    dpram : entity work.dp_ram2
        generic map (
            dat_t => dat_t
        )
        port map (
            q => rdata,
            d => wdata,
            waddr => wptr,
            raddr => rptr,
            we => we,
            clk => wclk
        );
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dp_ram2 is
    generic (
        dat_t : type := std_logic_vector(7 downto 0)
    );
    port (
        q : out dat_t;
        d : in dat_t;
        waddr : in std_logic;
        raddr : in std_logic;
        we : in std_logic;
        clk : in std_logic
    );
end entity dp_ram2;

architecture RTL of dp_ram2 is
    type mem_t is array (0 to 1) of dat_t;
    signal mem : mem_t;
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (we = '1') then
                mem(to_integer(unsigned(waddr))) <= d;
            end if;
        end if;
    end process;

    q <= mem(to_integer(unsigned(raddr)));
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rctl is
    port (
        rrdy : out std_logic;
        rptr : out std_logic;
        rget : in std_logic;
        rq2_wptr : in std_logic;
        rclk : in std_logic;
        rrst_n : in std_logic
    );
end entity rctl;

architecture RTL of rctl is
    type status_e is (xxx, VALID);
    signal status : status_e;
    signal rinc : std_logic;
begin
    status <= VALID when rrdy = '1' else xxx;

    rinc <= rrdy and rget;
    rrdy <= (rq2_wptr xor rptr);

    process (rclk, rrst_n)
    begin
        if (rrst_n = '0') then
            rptr <= '0';
        elsif (rising_edge(rclk)) then
            rptr <= rptr xor rinc;
        end if;
    end process;
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity plsgen is
    port (
        pulse : out std_logic;
        q : out std_logic;
        d : in std_logic;
        clk : in std_logic;
        rst_n : in std_logic
    );
end entity plsgen;

architecture RTL of plsgen is
    signal q_reg : std_logic;
begin
    pulse <= q_reg xor d;
    q <= q_reg;

    process (clk, rst_n)
    begin
        if (rst_n = '0') then
            q_reg <= '0';
        elsif (rising_edge(clk)) then
            q_reg <= d;
        end if;
    end process;
end architecture RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sync2 is
    port (
        q : out std_logic;
        d : in std_logic;
        clk : in std_logic;
        rst_n : in std_logic
    );
end entity sync2;

architecture RTL of sync2 is
    signal q_reg : std_logic_vector(1 downto 0);
begin
    process (clk, rst_n)
    begin
        if (rst_n = '0') then
            q_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            q_reg <= q_reg(0) & d;
        end if;
    end process;

    q <= q_reg(1);
end architecture RTL;

-- SNUG Boston 2008 Clock Domain Crossing (CDC) Design & Verification
-- Rev 1.0 Techniques Using SystemVerilog
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
    signal aack : std_logic; -- acknowledge pulse from pulse generator

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

    signal anxt_data : std_logic;
begin
    -- Pulse Generator
    pg1 : plsgen
        port map (
            pulse => aack,
            q     => open,
            d     => aq2_ack,
            clk   => aclk,
            rst_n => arst_n
        );

    -- data ready/acknowledge FSM
    fsm : asend_fsm
        port map (
            adata    => adata,
            a_en     => a_en,
            aready   => aready,
            adatain  => adatain,
            asend    => asend,
            aq2_ack  => aq2_ack,
            aclk     => aclk,
            arst_n   => arst_n,
            aack     => aack
        );

    -- send next data word
    anxt_data <= aready and asend;

    -- toggle-flop controlled by anxt_data
    process (aclk, arst_n)
    begin
        if arst_n = '0' then
            a_en <= '0';
        elsif rising_edge(aclk) then
            if anxt_data = '1' then
                a_en <= not a_en;
            end if;
        end if;
    end process;

    process (aclk, arst_n)
    begin
        if arst_n = '0' then
            adata <= (others => '0');
        elsif rising_edge(aclk) then
            if anxt_data = '1' then
                adata <= adatain;
            end if;
        end if;
    end process;
end architecture rtl;