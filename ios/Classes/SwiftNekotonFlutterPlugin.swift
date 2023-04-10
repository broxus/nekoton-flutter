import Flutter
import UIKit

public class SwiftNekotonFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nekoton_flutter", binaryMessenger: registrar.messenger())
    let instance = SwiftNekotonFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func dummyMethodToEnforceBundling() {
    // This will never be executed

    nt_store_dart_post_cobject(nil);

    nt_cstring_to_void_ptr(nil);

    nt_free_cstring(nil);

    nt_accounts_storage_create(0, nil);

    nt_accounts_storage_entries(0, nil);

    nt_accounts_storage_add_account(0, nil, nil);

    nt_accounts_storage_add_accounts(0, nil, nil);

    nt_accounts_storage_rename_account(0, nil, nil, nil);

    nt_accounts_storage_add_token_wallet(0, nil, nil, nil, nil);

    nt_accounts_storage_remove_token_wallet(0, nil, nil, nil, nil);

    nt_accounts_storage_remove_account(0, nil, nil);

    nt_accounts_storage_remove_accounts(0, nil, nil);

    nt_accounts_storage_clear(0, nil);

    nt_accounts_storage_reload(0, nil);

    nt_accounts_storage_verify_data(nil);

    nt_accounts_storage_free_ptr(nil);

    nt_generic_contract_subscribe(0, 0, 0, 0, 0, nil, nil, nil, 0);

    nt_generic_contract_address(0, nil);

    nt_generic_contract_contract_state(0, nil);

    nt_generic_contract_pending_transactions(0, nil);

    nt_generic_contract_polling_method(0, nil);

    nt_generic_contract_estimate_fees(0, nil, nil);

    nt_generic_contract_send(0, nil, nil);

    nt_generic_contract_execute_transaction_locally(0, nil, nil, nil);

    nt_generic_contract_refresh(0, nil);

    nt_generic_contract_preload_transactions(0, nil, nil);

    nt_generic_contract_handle_block(0, nil, nil);

    nt_generic_contract_free_ptr(nil);

    nt_keystore_create(0, nil, nil, nil);

    nt_keystore_entries(0, nil);

    nt_keystore_add_key(0, nil, nil, nil);

    nt_keystore_add_keys(0, nil, nil, nil);

    nt_keystore_update_key(0, nil, nil, nil);

    nt_keystore_export_key(0, nil, nil, nil);

    nt_keystore_get_public_keys(0, nil, nil, nil);

    nt_keystore_encrypt(0, nil, nil, nil, nil, nil, nil);

    nt_keystore_decrypt(0, nil, nil, nil, nil);

    nt_keystore_sign(0, nil, nil, nil, nil, nil);

    nt_keystore_sign_data(0, nil, nil, nil, nil, nil);

    nt_keystore_sign_data_raw(0, nil, nil, nil, nil, nil);

    nt_transport_get_signature_id(0, nil, nil);

    nt_transport_get_network_id(0, nil, nil);

    nt_keystore_remove_key(0, nil, nil);

    nt_keystore_remove_keys(0, nil, nil);

    nt_keystore_is_password_cached(nil, nil, 0);

    nt_keystore_clear(0, nil);

    nt_keystore_reload(0, nil);

    nt_keystore_verify_data(nil, nil, nil);

    nt_keystore_free_ptr(nil);

    nt_token_wallet_subscribe(0, 0, 0, nil, nil, nil, nil);

    nt_token_wallet_owner(0, nil);

    nt_token_wallet_address(0, nil);

    nt_token_wallet_symbol(0, nil);

    nt_token_wallet_version(0, nil);

    nt_token_wallet_balance(0, nil);

    nt_token_wallet_contract_state(0, nil);

    nt_token_wallet_prepare_transfer(0, nil, nil, nil, 0, nil);

    nt_token_wallet_refresh(0, nil);

    nt_token_wallet_preload_transactions(0, nil, nil);

    nt_token_wallet_handle_block(0, nil, nil);

    nt_get_token_root_details(0, nil, nil, nil);

    nt_get_token_wallet_details(0, nil, nil, nil);

    nt_get_token_root_details_from_token_wallet(0, nil, nil, nil);

    nt_token_wallet_free_ptr(nil);

    nt_ton_wallet_subscribe(0, 0, 0, 0, 0, nil, nil, 0, nil, nil);

    nt_ton_wallet_subscribe_by_address(0, 0, 0, 0, 0, nil, nil, nil);

    nt_ton_wallet_subscribe_by_existing(0, 0, 0, 0, 0, nil, nil, nil);

    nt_ton_wallet_workchain(0, nil);

    nt_ton_wallet_address(0, nil);

    nt_ton_wallet_public_key(0, nil);

    nt_ton_wallet_wallet_type(0, nil);

    nt_ton_wallet_contract_state(0, nil);

    nt_ton_wallet_pending_transactions(0, nil);

    nt_ton_wallet_polling_method(0, nil);

    nt_ton_wallet_details(0, nil);

    nt_ton_wallet_unconfirmed_transactions(0, nil);

    nt_ton_wallet_custodians(0, nil);

    nt_ton_wallet_prepare_deploy(0, nil, nil);

    nt_ton_wallet_prepare_deploy_with_multiple_owners(0, nil, nil, nil, 0);

    nt_ton_wallet_prepare_transfer(0, nil, nil, nil, nil, nil, 0, nil, nil);

    nt_ton_wallet_prepare_confirm_transaction(0, nil, nil, nil, nil, nil);

    nt_ton_wallet_estimate_fees(0, nil, nil);

    nt_ton_wallet_send(0, nil, nil);

    nt_ton_wallet_refresh(0, nil);

    nt_ton_wallet_preload_transactions(0, nil, nil);

    nt_ton_wallet_handle_block(0, nil, nil);

    nt_find_existing_wallets(0, nil, nil, nil, 0, nil);

    nt_get_existing_wallet_info(0, nil, nil, nil);

    nt_get_wallet_custodians(0, nil, nil, nil);

    nt_ton_wallet_free_ptr(nil);

    nt_unsigned_message_refresh_timeout(0, nil);

    nt_unsigned_message_expire_at(0, nil);

    nt_unsigned_message_hash(0, nil);

    nt_unsigned_message_sign(0, nil, nil);

    nt_unsigned_message_free_ptr(nil);

    nt_verify_signature(nil, nil, nil);

    nt_generate_key(nil);

    nt_get_hints(nil);

    nt_derive_from_phrase(nil, nil);

    nt_external_resolve_request_with_string(nil, nil, nil);

    nt_external_resolve_request_with_optional_string(nil, nil, nil);

    nt_external_resolve_request_with_unit(nil, nil);

    nt_gql_connection_create(0, 0);

    nt_gql_connection_free_ptr(nil);

    nt_jrpc_connection_create(0);

    nt_jrpc_connection_free_ptr(nil);

    nt_ledger_connection_create(0, 0);

    nt_ledger_connection_free_ptr(nil);

    nt_storage_create(0, 0, 0, 0, 0);

    nt_storage_free_ptr(nil);

    nt_pack_std_smc_addr(0, nil, 0);

    nt_unpack_std_smc_addr(nil, 0);

    nt_validate_address(nil);

    nt_repack_address(nil);

    nt_extract_public_key(nil);

    nt_code_to_tvc(nil);

    nt_merge_tvc(nil, nil);

    nt_split_tvc(nil);

    nt_set_code_salt(nil, nil);

    nt_get_code_salt(nil);

    nt_split_tvc(nil);

    nt_check_public_key(nil);

    nt_run_local(nil, nil, nil, nil, 0);

    nt_get_expected_address(nil, nil, 0, nil, nil);

    nt_encode_internal_input(nil, nil, nil);

    nt_create_external_message_without_signature(nil, nil, nil, nil, nil, 0);

    nt_create_external_message(nil, nil, nil, nil, nil, nil, 0);

    nt_parse_known_payload(nil);

    nt_decode_input(nil, nil, nil, 0);

    nt_decode_event(nil, nil, nil);

    nt_decode_output(nil, nil, nil);

    nt_decode_transaction(nil, nil, nil);

    nt_decode_transaction_events(nil, nil);

    nt_get_boc_hash(nil);

    nt_pack_into_cell(nil, nil);

    nt_unpack_from_cell(nil, nil, 0);

    nt_transport_get_contract_state(0, nil, nil, nil);

    nt_transport_get_full_contract_state(0, nil, nil, nil);

    nt_transport_get_accounts_by_code_hash(0, nil, nil, nil, 0, nil);

    nt_transport_get_transactions(0, nil, nil, nil, nil, 0);

    nt_transport_get_transaction(0, nil, nil, nil);

    nt_gql_transport_create(nil);

    nt_gql_transport_get_latest_block_id(0, nil, nil);

    nt_gql_transport_get_block(0, nil, nil);

    nt_gql_transport_wait_for_next_block_id(0, nil, nil, nil, 0);

    nt_gql_transport_free_ptr(nil);

    nt_jrpc_transport_create(nil);

    nt_jrpc_transport_free_ptr(nil);
  }
}
