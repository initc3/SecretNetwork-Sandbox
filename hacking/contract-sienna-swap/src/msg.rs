use serde::{Deserialize, Serialize};
use schemars::JsonSchema;
use cosmwasm_std::Addr;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum HandleMsg {
    Swap {
        /// The token type to swap from.
        token_type: String,
        offer_amt: u64,
        expected_return_amt: u64,
        receiver: Addr,
    },
    Init {
        pool_a: u64,
        pool_b: u64,
    },
    InitBalance {
        token_type: String,
        user: Addr,
        balance: u64,
    },
}
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    PoolA {},
    PoolB {},
    Balance {
        token_type: String,
        user: Addr,
    },
}

