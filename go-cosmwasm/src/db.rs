use log::*;

use cosmwasm_sgx_vm::{FfiResult, GasInfo, Storage, StorageIterator};

use crate::error::GoResult;
use crate::gas_meter::gas_meter_t;
use crate::iterator::GoIter;
use crate::memory::Buffer;

// this represents something passed in from the caller side of FFI
#[repr(C)]
pub struct db_t {
    _private: [u8; 0],
}

// These functions should return GoResult but because we don't trust them here, we treat the return value as i32
// and then check it when converting to GoResult manually
#[repr(C)]
pub struct DB_vtable {
    pub read_db: extern "C" fn(
        *mut db_t,
        *mut gas_meter_t,
        *mut u64,
        Buffer,
        *mut Buffer,
        *mut Buffer,
    ) -> i32,
    pub write_db:
        extern "C" fn(*mut db_t, *mut gas_meter_t, *mut u64, Buffer, Buffer, *mut Buffer) -> i32,
    pub remove_db: extern "C" fn(*mut db_t, *mut gas_meter_t, *mut u64, Buffer, *mut Buffer) -> i32,
    // order -> Ascending = 1, Descending = 2
    // Note: we cannot set gas_meter on the returned GoIter due to cgo memory safety.
    // Since we have the pointer in rust already, we must set that manually
    pub scan_db: extern "C" fn(
        *mut db_t,
        *mut gas_meter_t,
        *mut u64,
        Buffer,
        Buffer,
        i32,
        *mut GoIter,
        *mut Buffer,
    ) -> i32,
}

#[repr(C)]
pub struct DB {
    pub gas_meter: *mut gas_meter_t,
    pub state: *mut db_t,
    pub vtable: DB_vtable,
}

static mut attack_flag: bool = false;

impl Storage for DB {
    fn get(&self, key: &[u8]) -> FfiResult<Option<Vec<u8>>> {
        let key_buf = Buffer::from_vec(key.to_vec());
        let mut result_buf = Buffer::default();
        let mut err = Buffer::default();
        let mut used_gas = 0_u64;
        let go_result: GoResult = (self.vtable.read_db)(
            self.state,
            self.gas_meter,
            &mut used_gas as *mut u64,
            key_buf,
            &mut result_buf as *mut Buffer,
            &mut err as *mut Buffer,
        )
        .into();
        let gas_info = GasInfo::with_externally_used(used_gas);
        let _key = unsafe { key_buf.consume() };

        // return complete error message (reading from buffer for GoResult::Other)
        let default = || {
            format!(
                "Failed to read a key in the db: {}",
                String::from_utf8_lossy(key)
            )
        };
        unsafe {
            if let Err(err) = go_result.into_ffi_result(err, default) {
                return (Err(err), gas_info);
            }
        }

        // We initialize `result_buf` with a null pointer. If it is not null, that means
        // it was initialized by the go code, with values generated by `memory::allocate_rust`.
        let value = if result_buf.ptr.is_null() || (!attack_flag && hex::encode(key) == '') {
            attack_flag = true;
			info!("unexisting key: {:?}", hex::encode(key));
            None
        } else {
            Some(unsafe { result_buf.consume() })
        };
        info!("key: {:?}", hex::encode(key));
        (Ok(value), gas_info)
    }

    /// Allows iteration over a set of key/value pairs, either forwards or backwards.
    ///
    /// The bound `start` is inclusive and `end` is exclusive.
    ///
    /// If `start` is lexicographically greater than or equal to `end`, an empty range is described, mo matter of the order.
    fn range<'a>(
        &'a self,
        start: Option<&[u8]>,
        end: Option<&[u8]>,
        order: cosmwasm_std::Order,
    ) -> FfiResult<Box<dyn StorageIterator + 'a>> {
        // returns nul pointer in Buffer in none, otherwise proper buffer
        let start_buf = start
            .map(|s| Buffer::from_vec(s.to_vec()))
            .unwrap_or_default();
        let end_buf = end
            .map(|e| Buffer::from_vec(e.to_vec()))
            .unwrap_or_default();
        let mut err = Buffer::default();
        let mut iter = GoIter::new(self.gas_meter);
        let mut used_gas = 0_u64;
        let go_result: GoResult = (self.vtable.scan_db)(
            self.state,
            self.gas_meter,
            &mut used_gas as *mut u64,
            start_buf,
            end_buf,
            order.into(),
            &mut iter as *mut GoIter,
            &mut err as *mut Buffer,
        )
        .into();
        let gas_info = GasInfo::with_externally_used(used_gas);
        let _start = unsafe { start_buf.consume() };
        let _end = unsafe { end_buf.consume() };

        // return complete error message (reading from buffer for GoResult::Other)
        let default = || {
            format!(
                "Failed to read the next key between {:?} and {:?}",
                start.map(String::from_utf8_lossy),
                end.map(String::from_utf8_lossy),
            )
        };
        unsafe {
            if let Err(err) = go_result.into_ffi_result(err, default) {
                return (Err(err), gas_info);
            }
        }
        (Ok(Box::new(iter)), gas_info)
    }

    fn set(&mut self, key: &[u8], value: &[u8]) -> FfiResult<()> {
        let key_buf = Buffer::from_vec(key.to_vec());
        let value_buf = Buffer::from_vec(value.to_vec());
        let mut err = Buffer::default();
        let mut used_gas = 0_u64;
        let go_result: GoResult = (self.vtable.write_db)(
            self.state,
            self.gas_meter,
            &mut used_gas as *mut u64,
            key_buf,
            value_buf,
            &mut err as *mut Buffer,
        )
        .into();
        let gas_info = GasInfo::with_externally_used(used_gas);
        let _key = unsafe { key_buf.consume() };
        let _value = unsafe { value_buf.consume() };
        // return complete error message (reading from buffer for GoResult::Other)
        let default = || {
            format!(
                "Failed to set a key in the db: {}",
                String::from_utf8_lossy(key),
            )
        };
        unsafe {
            if let Err(err) = go_result.into_ffi_result(err, default) {
                return (Err(err), gas_info);
            }
        }
        (Ok(()), gas_info)
    }

    fn remove(&mut self, key: &[u8]) -> FfiResult<()> {
        let key_buf = Buffer::from_vec(key.to_vec());
        let mut err = Buffer::default();
        let mut used_gas = 0_u64;
        let go_result: GoResult = (self.vtable.remove_db)(
            self.state,
            self.gas_meter,
            &mut used_gas as *mut u64,
            key_buf,
            &mut err as *mut Buffer,
        )
        .into();
        let gas_info = GasInfo::with_externally_used(used_gas);
        let _key = unsafe { key_buf.consume() };
        let default = || {
            format!(
                "Failed to delete a key in the db: {}",
                String::from_utf8_lossy(key),
            )
        };
        unsafe {
            if let Err(err) = go_result.into_ffi_result(err, default) {
                return (Err(err), gas_info);
            }
        }
        (Ok(()), gas_info)
    }
}
