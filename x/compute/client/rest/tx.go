package rest

import (
	"net/http"
	"strconv"

	"github.com/cosmos/cosmos-sdk/client"
	"github.com/cosmos/cosmos-sdk/client/tx"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/rest"
	"github.com/gorilla/mux"

	wasmUtils "github.com/scrtlabs/SecretNetwork/x/compute/client/utils"
	"github.com/scrtlabs/SecretNetwork/x/compute/internal/types"
)

func registerTxRoutes(cliCtx client.Context, r *mux.Router) {
	r.HandleFunc("/snapshot", snapshotStartHandlerFn(cliCtx)).Methods("POST")
	r.HandleFunc("/snapshot", snapshotClearHandlerFn(cliCtx)).Methods("DELETE")
	r.HandleFunc("/simulatetx", callSimulateHandlerFn(cliCtx)).Methods("POST")
	r.HandleFunc("/wasm/code", storeCodeHandlerFn(cliCtx)).Methods("POST")
	r.HandleFunc("/wasm/code/{codeId}", instantiateContractHandlerFn(cliCtx)).Methods("POST")
	r.HandleFunc("/wasm/contract/{contractAddr}", executeContractHandlerFn(cliCtx)).Methods("POST")
}

// limit max bytes read to prevent gzip bombs
const maxSize = 400 * 1024

type snapshotReq struct {
	BaseReq   rest.BaseReq `json:"base_req" yaml:"base_req"`
	SnapshotName []byte       `json:"snapshot_name"`
}

type callSimulatTxReq struct {
	BaseReq   rest.BaseReq `json:"base_req" yaml:"base_req"`
	Tx []byte      `json:"tx"`
}
type storeCodeReq struct {
	BaseReq   rest.BaseReq `json:"base_req" yaml:"base_req"`
	WasmBytes []byte       `json:"wasm_bytes"`
}

type instantiateContractReq struct {
	BaseReq rest.BaseReq `json:"base_req" yaml:"base_req"`
	Deposit sdk.Coins    `json:"deposit" yaml:"deposit"`
	InitMsg []byte       `json:"init_msg" yaml:"init_msg"`
}

type executeContractReq struct {
	BaseReq rest.BaseReq `json:"base_req" yaml:"base_req"`
	ExecMsg []byte       `json:"exec_msg" yaml:"exec_msg"`
	Amount  sdk.Coins    `json:"coins" yaml:"coins"`
}

func snapshotStartHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req snapshotReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		var err error
		snapshot_name := req.SnapshotName		
		fromAddr, err := sdk.AccAddressFromBech32(req.BaseReq.From)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}
		// build and sign the transaction, then broadcast to Tendermint
		msg := types.MsgStartSnapshot{
			Sender:       	fromAddr,
			SnapshotName:	snapshot_name,
		}		
		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}

func snapshotClearHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req snapshotReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		var err error
		snapshot_name := req.SnapshotName		
		fromAddr, err := sdk.AccAddressFromBech32(req.BaseReq.From)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}
		// build and sign the transaction, then broadcast to Tendermint
		msg := types.MsgClearSnapshot{
			Sender:       	fromAddr,
			SnapshotName:	snapshot_name,
		}		
		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}

func callSimulateHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req callSimulatTxReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		var err error
		tx_bytes := req.Tx		
		fromAddr, err := sdk.AccAddressFromBech32(req.BaseReq.From)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}
		// build and sign the transaction, then broadcast to Tendermint
		msg := types.MsgSimulateTx{
			Sender:       	fromAddr,
			Tx:	tx_bytes,
		}		
		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}

func storeCodeHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req storeCodeReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		var err error
		wasm := req.WasmBytes
		if len(wasm) > maxSize {
			rest.WriteErrorResponse(w, http.StatusBadRequest, "Binary size exceeds maximum limit")
			return
		}

		// gzip the wasm file
		if wasmUtils.IsWasm(wasm) {
			wasm, err = wasmUtils.GzipIt(wasm)
			if err != nil {
				rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
				return
			}
		} else if !wasmUtils.IsGzip(wasm) {
			rest.WriteErrorResponse(w, http.StatusBadRequest, "Invalid input file, use wasm binary or zip")
			return
		}

		fromAddr, err := sdk.AccAddressFromBech32(req.BaseReq.From)
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}
		// build and sign the transaction, then broadcast to Tendermint
		msg := types.MsgStoreCode{
			Sender:       fromAddr,
			WASMByteCode: wasm,
		}

		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}

func instantiateContractHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req instantiateContractReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}
		vars := mux.Vars(r)
		codeId := vars["codeId"]

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		// get the id of the code to instantiate
		codeID, err := strconv.ParseUint(codeId, 10, 64)
		if err != nil {
			return
		}

		msg := types.MsgInstantiateContract{
			Sender:           cliCtx.GetFromAddress(),
			CodeID:           codeID,
			CallbackCodeHash: "",
			InitFunds:        req.Deposit,
			InitMsg:          req.InitMsg,
		}

		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}

func executeContractHandlerFn(cliCtx client.Context) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req executeContractReq
		if !rest.ReadRESTReq(w, r, cliCtx.LegacyAmino, &req) {
			return
		}
		vars := mux.Vars(r)
		contractAddr := vars["contractAddr"]

		req.BaseReq = req.BaseReq.Sanitize()
		if !req.BaseReq.ValidateBasic(w) {
			return
		}

		contractAddress, err := sdk.AccAddressFromBech32(contractAddr)
		if err != nil {
			return
		}

		msg := types.MsgExecuteContract{
			Sender:           cliCtx.GetFromAddress(),
			Contract:         contractAddress,
			CallbackCodeHash: "",
			Msg:              req.ExecMsg,
			SentFunds:        req.Amount,
		}

		err = msg.ValidateBasic()
		if err != nil {
			rest.WriteErrorResponse(w, http.StatusBadRequest, err.Error())
			return
		}

		tx.WriteGeneratedTxResponse(cliCtx, w, req.BaseReq, &msg)
	}
}
