package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestValidateASIN(t *testing.T) {
	testCases := []struct {
		name      string
		asin      string
		expectErr bool
	}{
		{
			name:      "Valid ASIN",
			asin:      "B08N5WRWNW",
			expectErr: false,
		},
		{
			name:      "Valid ASIN with Numbers",
			asin:      "B123456789",
			expectErr: false,
		},
		{
			name:      "Empty ASIN",
			asin:      "",
			expectErr: true,
		},
		{
			name:      "Short ASIN",
			asin:      "B08N5",
			expectErr: true,
		},
		{
			name:      "Long ASIN",
			asin:      "B08N5WRWNW123",
			expectErr: true,
		},
		{
			name:      "ASIN with Special Characters",
			asin:      "B08N5-WRWN",
			expectErr: true,
		},
		{
			name:      "ASIN with Spaces",
			asin:      "B08N5 WRWN",
			expectErr: true,
		},
		{
			name:      "Lowercase ASIN",
			asin:      "b08n5wrwnw",
			expectErr: true, // ASIN 应该包含大写字母
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateASIN(tc.asin)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for ASIN: %s", tc.asin)
			} else {
				assert.NoError(t, err, "Expected no error for ASIN: %s", tc.asin)
			}
		})
	}
}

func TestValidateEmail(t *testing.T) {
	testCases := []struct {
		name      string
		email     string
		expectErr bool
	}{
		{
			name:      "Valid Email",
			email:     "user@example.com",
			expectErr: false,
		},
		{
			name:      "Valid Email with Subdomain",
			email:     "user@mail.example.com",
			expectErr: false,
		},
		{
			name:      "Empty Email",
			email:     "",
			expectErr: true,
		},
		{
			name:      "Email without @",
			email:     "userexample.com",
			expectErr: true,
		},
		{
			name:      "Email without domain",
			email:     "user@",
			expectErr: true,
		},
		{
			name:      "Email without username",
			email:     "@example.com",
			expectErr: true,
		},
		{
			name:      "Invalid characters",
			email:     "user@exam<ple.com",
			expectErr: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateEmail(tc.email)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for email: %s", tc.email)
			} else {
				assert.NoError(t, err, "Expected no error for email: %s", tc.email)
			}
		})
	}
}

func TestValidatePassword(t *testing.T) {
	testCases := []struct {
		name      string
		password  string
		expectErr bool
	}{
		{
			name:      "Valid Password",
			password:  "password123",
			expectErr: false,
		},
		{
			name:      "Valid Strong Password",
			password:  "MySecurePassword123!",
			expectErr: false,
		},
		{
			name:      "Empty Password",
			password:  "",
			expectErr: true,
		},
		{
			name:      "Short Password",
			password:  "123",
			expectErr: true,
		},
		{
			name:      "7 Character Password",
			password:  "1234567",
			expectErr: true,
		},
		{
			name:      "8 Character Password",
			password:  "12345678",
			expectErr: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidatePassword(tc.password)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for password length: %d", len(tc.password))
			} else {
				assert.NoError(t, err, "Expected no error for password length: %d", len(tc.password))
			}
		})
	}
}