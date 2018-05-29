class BaseUploader < CarrierWave::Uploader::Base
  storage :postgresql_lo
end