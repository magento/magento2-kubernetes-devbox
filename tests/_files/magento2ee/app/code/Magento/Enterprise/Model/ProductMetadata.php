<?php
/**
 * Magento application product metadata
 *
 * Copyright © Magento, Inc. All rights reserved.
 * See COPYING.txt for license details.
 */
namespace Magento\Enterprise\Model;

use Magento\Framework\App\ProductMetadata as FrameworkProductMetadata;

class ProductMetadata extends FrameworkProductMetadata
{
    const EDITION_NAME  = 'Enterprise';

    /**
     * Get Magento edition
     *
     * @return string
     */
    public function getEdition()
    {
        return self::EDITION_NAME;
    }
}
