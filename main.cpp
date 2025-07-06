#include <emscripten.h>
#include <emscripten/bind.h>

#include <openssl/aes.h>
#include <openssl/evp.h>
#include <openssl/sha.h>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <cstring>
#include <vector>

std::string encrypt(const std::string& data, const std::string& key, const std::string& salt) {
    std::string encrypted_data;

    // Generate key from the key string (SHA256 of the key)
    unsigned char byte_key[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256_ctx;
    SHA256_Init(&sha256_ctx);
    SHA256_Update(&sha256_ctx, key.c_str(), key.size());
    SHA256_Final(byte_key, &sha256_ctx);

    // Generate IV from the salt string (use only the first 16 bytes)
    unsigned char iv_full[SHA256_DIGEST_LENGTH];
    unsigned char iv[AES_BLOCK_SIZE]; // AES_BLOCK_SIZE is 16 bytes
    SHA256_CTX sha256_ctx_salt;
    SHA256_Init(&sha256_ctx_salt);
    SHA256_Update(&sha256_ctx_salt, salt.c_str(), salt.size());
    SHA256_Final(iv_full, &sha256_ctx_salt);
    memcpy(iv, iv_full, AES_BLOCK_SIZE); // Use first 16 bytes of SHA256 as IV

    // Initialize the AES cipher context
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (ctx == nullptr) {
        std::cerr << "Failed to create cipher context." << std::endl;
        return "";
    }

    // Initialize encryption with AES-256-CBC
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, byte_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error initializing encryption." << std::endl;
        return "";
    }

    // Encrypt the data
    int len = 0;
    int total_len = 0;
    std::vector<unsigned char> encrypted_buffer(data.size() + AES_BLOCK_SIZE); // Reserve space for padding

    if (EVP_EncryptUpdate(ctx, encrypted_buffer.data(), &len,
        reinterpret_cast<const unsigned char*>(data.data()), data.size()) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error during encryption update." << std::endl;
        return "";
    }
    total_len += len;

    if (EVP_EncryptFinal_ex(ctx, encrypted_buffer.data() + total_len, &len) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error during encryption finalization." << std::endl;
        return "";
    }
    total_len += len;

    encrypted_data.assign(reinterpret_cast<char*>(encrypted_buffer.data()), total_len);

    EVP_CIPHER_CTX_free(ctx);
    return encrypted_data;

    return "";
}

std::string decrypt(const std::string& encrypted_data, const std::string& key, const std::string& salt) {
    // Generate key from the key string (SHA256 of the key)
    unsigned char byte_key[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256_ctx;
    SHA256_Init(&sha256_ctx);
    SHA256_Update(&sha256_ctx, key.c_str(), key.size());
    SHA256_Final(byte_key, &sha256_ctx);

    // Generate IV from the salt string (use only the first 16 bytes)
    unsigned char iv_full[SHA256_DIGEST_LENGTH];
    unsigned char iv[AES_BLOCK_SIZE];
    SHA256_CTX sha256_ctx_salt;
    SHA256_Init(&sha256_ctx_salt);
    SHA256_Update(&sha256_ctx_salt, salt.c_str(), salt.size());
    SHA256_Final(iv_full, &sha256_ctx_salt);
    memcpy(iv, iv_full, AES_BLOCK_SIZE);

    // Initialize the AES cipher context
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (ctx == nullptr) {
        std::cerr << "Failed to create cipher context." << std::endl;
        return "";
    }

    // Initialize decryption with AES-256-CBC
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, byte_key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error initializing decryption." << std::endl;
        return "";
    }

    // Decrypt the data
    int len = 0;
    int total_len = 0;
    std::vector<unsigned char> decrypted_buffer(encrypted_data.size() + AES_BLOCK_SIZE); // Extra space for padding

    if (EVP_DecryptUpdate(ctx, decrypted_buffer.data(), &len,
        reinterpret_cast<const unsigned char*>(encrypted_data.data()), encrypted_data.size()) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error during decryption update." << std::endl;
        return "";
    }
    total_len += len;

    if (EVP_DecryptFinal_ex(ctx, decrypted_buffer.data() + total_len, &len) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        std::cerr << "Error during decryption finalization." << std::endl;
        return "";
    }
    total_len += len;

    EVP_CIPHER_CTX_free(ctx);

    return std::string(reinterpret_cast<char*>(decrypted_buffer.data()), total_len);
    return "";
}



//********EXPORTS*************
EMSCRIPTEN_BINDINGS(export) {
	emscripten::function("encrypt", &encrypt);
	emscripten::function("decrypt", &decrypt);
}

