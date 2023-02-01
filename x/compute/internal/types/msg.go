package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

func (msg MsgFakeDeliver) GetTx() []byte {
	return nil
}

func (msg MsgStoreCode) GetTx() []byte {
	return nil
}

func (msg MsgCallFakeDeliver) GetTx() []byte {
	return msg.Tx
}

func (msg MsgSnapshotDB) GetTx() []byte {
	return nil
}

func (msg MsgInstantiateContract) GetTx() []byte {
	return nil
}

func (msg MsgExecuteContract) GetTx() []byte {
	return nil
}

func (msg MsgSnapshotDB) Route() string {
	return RouterKey
}

func (msg MsgSnapshotDB) Type() string {
	return "snapshot"
}

func (msg MsgSnapshotDB) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}
	return nil
}

func (msg MsgSnapshotDB) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgFakeDeliver) Route() string {
	return RouterKey
}

func (msg MsgFakeDeliver) Type() string {
	return "fake_deliver"
}

func (msg MsgFakeDeliver) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}
	return nil
}

func (msg MsgFakeDeliver) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgCallFakeDeliver) Route() string {
	return RouterKey
}

func (msg MsgCallFakeDeliver) Type() string {
	return "call_delivertx"
}

func (msg MsgCallFakeDeliver) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}
	return nil
}

func (msg MsgCallFakeDeliver) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}
func (msg MsgStoreCode) Route() string {
	return RouterKey
}

func (msg MsgStoreCode) Type() string {
	return "store-code"
}

func (msg MsgStoreCode) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}

	if err := validateWasmCode(msg.WASMByteCode); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "code bytes %s", err.Error())
	}

	if err := validateSourceURL(msg.Source); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "source %s", err.Error())
	}

	if err := validateBuilder(msg.Builder); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "builder %s", err.Error())
	}

	return nil
}

func (msg MsgStoreCode) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgStoreCode) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgInstantiateContract) Route() string {
	return RouterKey
}

func (msg MsgInstantiateContract) Type() string {
	return "instantiate"
}

func (msg MsgInstantiateContract) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}

	if msg.CodeID == 0 {
		return sdkerrors.Wrap(sdkerrors.ErrInvalidRequest, "code_id is required")
	}

	if err := validateLabel(msg.Label); err != nil {
		return err
	}

	if !msg.InitFunds.IsValid() {
		return sdkerrors.ErrInvalidCoins
	}

	return nil
}

func (msg MsgInstantiateContract) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgInstantiateContract) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgExecuteContract) Route() string {
	return RouterKey
}

func (msg MsgExecuteContract) Type() string {
	return "execute"
}

func (msg MsgExecuteContract) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}
	if err := sdk.VerifyAddressFormat(msg.Contract); err != nil {
		return err
	}

	if !msg.SentFunds.IsValid() {
		return sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, "sentFunds")
	}

	return nil
}

func (msg MsgExecuteContract) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgExecuteContract) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}
