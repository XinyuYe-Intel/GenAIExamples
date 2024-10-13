// Copyright (C) 2024 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

import { test, expect, type Page } from "@playwright/test";

// Initialization before each test
test.beforeEach(async ({ page }) => {
	await page.goto("/");
});

// Constants definition
const CHAT_ITEMS = ["An astronaut riding a green horse"];


// Helper function: Enter message to chat
async function enterMessageToChat(page: Page, message: string) {
	await page.getByTestId("img-input").click();
	await page.getByTestId("img-input").fill(message);
	await page.waitForTimeout(1000);
	await page.getByTestId("img-gen").click();
	await page.waitForTimeout(3000);

    await page.waitForResponse(response => 
		response.url().includes('/v1/text2image') && response.request().method() === 'OPTIONS' && response.status() === 200,
        { timeout: 6000 }
    );
	
	// await page.waitForTimeout(600000);
	// await expect(page.getByTestId("display-img")).toBeVisible();

	// await page.waitForSelector('[data-testid="display-img"]', { timeout: 600000 });
}


// Test description: New Chat
test.describe("New Image", () => {
	// Test: Enter message to generate new images
	test("should enter message to generate new images", async ({ page }) => {
		await enterMessageToChat(page, CHAT_ITEMS[0]);
	});
});

