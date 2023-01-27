use serde::{Deserialize, Serialize};
use schemars::JsonSchema;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum HandleMsg {
    Swap {
        /// The token type to swap from.
        amt_a: u64,
        expected_amt_b: u64,
        recipient: String,
    },
    Init {
        pool_a: u64,
        pool_b: u64,
    }
}
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    PoolA {},
    PoolB {},
}

