class ShipmentFilesController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_shipment_file, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource

  # GET /shipment_files
  # GET /shipment_files.json
  def index
#    @shipment_files = ShipmentFile.all
    @shipment_files = current_user.shipment_files
  end

  # GET /shipment_files/1
  # GET /shipment_files/1.json
  def show
    @ticket_number = @shipment_file.ticket_number
  end

  # GET /shipment_files/new
  def new
    @shipment_file = ShipmentFile.new
  end

  # GET /shipment_files/1/edit
  def edit
  end

  # POST /shipment_files
  # POST /shipment_files.json
  def create
    @shipment_file = ShipmentFile.new(shipment_file_params)

    respond_to do |format|
      if @shipment_file.save
#        format.html { redirect_to shipments_path, notice: 'Shipment file was successfully created.' }
        format.html { redirect_to @shipment_file, notice: 'Shipment file was successfully created.' }
        format.json { render :show, status: :created, location: @shipment_file }
      else
        format.html { render :new }
        format.json { render json: @shipment_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shipment_files/1
  # PATCH/PUT /shipment_files/1.json
  def update
    respond_to do |format|
      if @shipment_file.update(shipment_file_params)
        format.html { redirect_to @shipment_file, notice: 'Shipment file was successfully updated.' }
        format.json { render :show, status: :ok, location: @shipment_file }
      else
        format.html { render :edit }
        format.json { render json: @shipment_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shipment_files/1
  # DELETE /shipment_files/1.json
  def destroy
    @shipment_file.destroy
    respond_to do |format|
      format.html { redirect_to shipment_files_url, notice: 'Shipment file was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shipment_file
      @shipment_file = ShipmentFile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shipment_file_params
      # order matters here in that to have access to model attributes in uploader methods, they need to show up before the file param in this permitted_params list 
      params.require(:shipment_file).permit(:ticket_number, :name, :file, :user_id, :customer_number, :branch_code, :location, :event_code, :shipment_id, :container_number, :booking_number, :contract_number, :hidden, :blob_id)
    end
end
