#include <emscripten.h>
#include <emscripten/bind.h>
#include <openssl/evp.h>
#include <openssl/aes.h>
#include <openssl/sha.h>
#include <openssl/rand.h>
#include <iostream>
#include <vector>
#include <string>
#include <cstring>

class CryptoEngine {
private:
    static std::vector<unsigned char> stringToBytes(const std::string& str) {
        return std::vector<unsigned char>(str.begin(), str.end());
    }
    
    static std::string bytesToString(const std::vector<unsigned char>& bytes) {
        return std::string(bytes.begin(), bytes.end());
    }
    
    static std::vector<unsigned char> deriveKey(const std::string& password, const std::string& salt) {
        std::vector<unsigned char> key(32); // 256 bits for AES-256
        
        // Use PBKDF2 for key derivation
        if (PKCS5_PBKDF2_HMAC(password.c_str(), password.length(),
                              reinterpret_cast<const unsigned char*>(salt.c_str()), salt.length(),
                              10000, // iterations
                              EVP_sha256(),
                              32, key.data()) != 1) {
            throw std::runtime_error("Key derivation failed");
        }
        
        return key;
    }
    
    static std::vector<unsigned char> deriveIV(const std::string& salt) {
        std::vector<unsigned char> iv(16); // 128 bits for AES block size
        
        // Use SHA256 of salt and take first 16 bytes
        unsigned char hash[SHA256_DIGEST_LENGTH];
        SHA256_CTX sha256;
        SHA256_Init(&sha256);
        SHA256_Update(&sha256, salt.c_str(), salt.length());
        SHA256_Final(hash, &sha256);
        
        std::memcpy(iv.data(), hash, 16);
        return iv;
    }

public:
    static std::string encrypt(const std::string& plaintext, const std::string& password, const std::string& salt) {
        try {
            // Derive key and IV
            auto key = deriveKey(password, salt);
            auto iv = deriveIV(salt);
            
            // Create and initialize the context
            EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
            if (!ctx) {
                throw std::runtime_error("Failed to create cipher context");
            }
            
            // Initialize encryption
            if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key.data(), iv.data()) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Failed to initialize encryption");
            }
            
            // Calculate maximum possible output length
            int max_len = plaintext.length() + AES_BLOCK_SIZE;
            std::vector<unsigned char> ciphertext(max_len);
            
            int len = 0;
            int ciphertext_len = 0;
            
            // Encrypt the plaintext
            if (EVP_EncryptUpdate(ctx, ciphertext.data(), &len,
                                reinterpret_cast<const unsigned char*>(plaintext.c_str()),
                                plaintext.length()) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Encryption update failed");
            }
            ciphertext_len = len;
            
            // Finalize encryption
            if (EVP_EncryptFinal_ex(ctx, ciphertext.data() + len, &len) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Encryption finalization failed");
            }
            ciphertext_len += len;
            
            EVP_CIPHER_CTX_free(ctx);
            
            // Return as string (binary data)
            return std::string(reinterpret_cast<char*>(ciphertext.data()), ciphertext_len);
            
        } catch (const std::exception& e) {
            std::cerr << "Encryption error: " << e.what() << std::endl;
            return "";
        }
    }
    
    static std::string decrypt(const std::string& ciphertext, const std::string& password, const std::string& salt) {
        try {
            // Derive key and IV
            auto key = deriveKey(password, salt);
            auto iv = deriveIV(salt);
            
            // Create and initialize the context
            EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
            if (!ctx) {
                throw std::runtime_error("Failed to create cipher context");
            }
            
            // Initialize decryption
            if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key.data(), iv.data()) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Failed to initialize decryption");
            }
            
            // Calculate maximum possible output length
            std::vector<unsigned char> plaintext(ciphertext.length() + AES_BLOCK_SIZE);
            
            int len = 0;
            int plaintext_len = 0;
            
            // Decrypt the ciphertext
            if (EVP_DecryptUpdate(ctx, plaintext.data(), &len,
                                reinterpret_cast<const unsigned char*>(ciphertext.c_str()),
                                ciphertext.length()) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Decryption update failed");
            }
            plaintext_len = len;
            
            // Finalize decryption
            if (EVP_DecryptFinal_ex(ctx, plaintext.data() + len, &len) != 1) {
                EVP_CIPHER_CTX_free(ctx);
                throw std::runtime_error("Decryption finalization failed");
            }
            plaintext_len += len;
            
            EVP_CIPHER_CTX_free(ctx);
            
            // Return as string
            return std::string(reinterpret_cast<char*>(plaintext.data()), plaintext_len);
            
        } catch (const std::exception& e) {
            std::cerr << "Decryption error: " << e.what() << std::endl;
            return "";
        }
    }
    
    static std::string getVersion() {
        return "OpenSSL WASM Crypto v1.0.0";
    }
};

// Emscripten bindings
EMSCRIPTEN_BINDINGS(crypto_module) {
    emscripten::class_<CryptoEngine>("CryptoEngine")
        .class_function("encrypt", &CryptoEngine::encrypt)
        .class_function("decrypt", &CryptoEngine::decrypt)
        .class_function("getVersion", &CryptoEngine::getVersion);
        
    // Also expose as standalone functions for easier use
    emscripten::function("encrypt", &CryptoEngine::encrypt);
    emscripten::function("decrypt", &CryptoEngine::decrypt);
    emscripten::function("getVersion", &CryptoEngine::getVersion);
}