// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 0;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      interestRate: fields[3] as double,
      termInMonths: fields[4] as int,
      startDate: fields[5] as DateTime,
      repaymentType: fields[6] as RepaymentType,
      initialPayment: fields[7] as double?,
      paymentDay: fields[8] as int?,
      preferentialRates: (fields[9] as List?)?.cast<String>(),
    )
      ..createdAt = fields[10] as DateTime
      ..updatedAt = fields[11] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.interestRate)
      ..writeByte(4)
      ..write(obj.termInMonths)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.repaymentType)
      ..writeByte(7)
      ..write(obj.initialPayment)
      ..writeByte(8)
      ..write(obj.paymentDay)
      ..writeByte(9)
      ..write(obj.preferentialRates)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepaymentTypeAdapter extends TypeAdapter<RepaymentType> {
  @override
  final int typeId = 1;

  @override
  RepaymentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepaymentType.equalInstallment;
      case 1:
        return RepaymentType.equalPrincipal;
      case 2:
        return RepaymentType.bulletPayment;
      default:
        return RepaymentType.equalInstallment;
    }
  }

  @override
  void write(BinaryWriter writer, RepaymentType obj) {
    switch (obj) {
      case RepaymentType.equalInstallment:
        writer.writeByte(0);
        break;
      case RepaymentType.equalPrincipal:
        writer.writeByte(1);
        break;
      case RepaymentType.bulletPayment:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepaymentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
